import UIKit
import FinClipChatKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  var coordinator: ChatKitCoordinator?
  var modelManager: LocalLLMModelManager?
  private var modelDownloader: ModelDownloader?
  private var downloadSession: URLSession?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)
    
    // Initialize ChatKitCoordinator
    let config = NeuronKitConfig.default(serverURL: AppConfig.defaultServerURL)
        .withUserId(AppConfig.defaultUserId)
    let coordinator = ChatKitCoordinator(config: config)
    self.coordinator = coordinator
    
    // Configure network adapter based on current mode
    configureNetworkAdapter(runtime: coordinator.runtime, mode: AppConfig.currentMode)
    
    let rootViewController = DrawerContainerViewController(coordinator: coordinator)
    window.rootViewController = rootViewController
    window.makeKeyAndVisible()

    self.window = window
  }
  
  private func configureNetworkAdapter(runtime: NeuronRuntime, mode: ConnectionMode) {
    print("🔄 [SceneDelegate] configureNetworkAdapter called with mode: \(mode == .local ? "LOCAL" : "REMOTE")")
    switch mode {
    case .local:
      print("📱 [SceneDelegate] Configuring LOCAL mode...")
      print("✅ [SceneDelegate] Using MediaPipe LLM Inference API")
      
      // CRITICAL: Register LocalLLMURLProtocol and create adapter FIRST
      // This ensures requests are intercepted even if model isn't loaded yet
      URLProtocol.registerClass(LocalLLMURLProtocol.self)
      print("✅ [SceneDelegate] LocalLLMURLProtocol registered")
      
      // Create adapter with LocalLLMURLProtocol immediately
      // The URLProtocol will handle requests even if model is still loading
      let mockURL = URL(string: "https://local-llm.local/agent")!
      let adapter = AGUI_Adapter(
        baseEventURL: mockURL,
        connectionMode: .postStream,
        sessionFactory: { configuration, delegate in
          // Create a new configuration with LocalLLMURLProtocol
          let sessionConfig = URLSessionConfiguration.default
          sessionConfig.protocolClasses = [LocalLLMURLProtocol.self]
          sessionConfig.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest
          sessionConfig.timeoutIntervalForResource = configuration.timeoutIntervalForResource
          print("🔧 [SceneDelegate] Creating URLSession with LocalLLMURLProtocol in sessionFactory")
          return URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
        }
      )
      runtime.setNetworkAdapter(adapter)
      print("✅ [SceneDelegate] Local LLM adapter configured (model may still be loading)")
      print("   Base URL: \(mockURL)")
      print("   All requests to this URL will be intercepted by LocalLLMURLProtocol")
      print("   URLProtocol will also intercept requests to 127.0.0.1 and localhost")
      
      // Check if model exists, download if needed
      print("🔍 [SceneDelegate] Checking for model directory...")
      if let modelDir = getModelDirectory() {
        // Model directory found (either in bundle or documents)
        print("✅ [SceneDelegate] Model directory found: \(modelDir.path)")
        
        print("🔍 [SceneDelegate] Checking for model path...")
        guard let modelPath = getModelPath() else {
          print("❌ [SceneDelegate] Could not determine model path")
          print("   Model directory exists but gemma-3-270m-it-int8.task not found")
          print("   URLProtocol is registered but model manager not available")
          print("   Requests will be intercepted but will fail until model is loaded")
          return
        }
        print("✅ [SceneDelegate] Model path found: \(modelPath.path)")
        
        print("🔍 [SceneDelegate] Checking if model is downloaded...")
        if !isModelDownloaded() {
          print("📥 [SceneDelegate] Model not found, starting download...")
          print("   Model directory: \(modelDir.path)")
          print("   Expected file: gemma-3-270m-it-int8.task")
          downloadModel(to: modelDir) { [weak self] success in
            guard let self = self, success else {
              print("❌ [SceneDelegate] Model download failed")
              print("   URLProtocol is registered but model manager not available")
              print("   Requests will be intercepted but will fail until model is loaded")
              return
            }
            // Model downloaded, now load it
            print("✅ [SceneDelegate] Model download completed, starting load...")
            // Re-get model path after download
            if let downloadedModelPath = self.getModelPath() {
              self.initializeAndLoadModel(modelPath: downloadedModelPath, runtime: runtime)
            } else {
              print("❌ [SceneDelegate] Could not get model path after download")
            }
          }
        } else {
          // Model exists, load it
          print("✅ [SceneDelegate] Model found, starting load...")
          print("   Model directory: \(modelDir.path)")
          print("   Model path: \(modelPath.path)")
          print("   All required files present - proceeding with load")
          initializeAndLoadModel(modelPath: modelPath, runtime: runtime)
        }
      } else {
        // Model directory not found - create documents directory and download
        print("❌ [SceneDelegate] Model not found in bundle or documents")
        print("   Creating documents directory and starting download...")
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Model file is placed directly in models/ directory, not in a subdirectory
        let documentsModelDir = documentsDir.appendingPathComponent("models")
        
        // Create directory if it doesn't exist
        do {
          try FileManager.default.createDirectory(at: documentsModelDir, withIntermediateDirectories: true)
          print("✅ [SceneDelegate] Created model directory: \(documentsModelDir.path)")
        } catch {
          print("❌ [SceneDelegate] Failed to create model directory: \(error)")
          print("   URLProtocol is registered but model manager not available")
          return
        }
        
        // Download model to documents directory
        print("📥 [SceneDelegate] Starting model download to: \(documentsModelDir.path)")
        print("   Expected file: gemma-3-270m-it-int8.task")
        print("   Note: Model file should be placed in Models directory manually")
        downloadModel(to: documentsModelDir) { [weak self] success in
          guard let self = self, success else {
            print("❌ [SceneDelegate] Model download failed")
            print("   URLProtocol is registered but model manager not available")
            print("   Requests will be intercepted but will fail until model is loaded")
            return
          }
          // Model downloaded, now load it
          print("✅ [SceneDelegate] Model download completed, starting load...")
          // Get model path after download
          if let downloadedModelPath = self.getModelPath() {
            self.initializeAndLoadModel(modelPath: downloadedModelPath, runtime: runtime)
          } else {
            print("❌ [SceneDelegate] Could not get model path after download")
          }
        }
      }
      
    case .remote:
      // CRITICAL: Disable LocalLLMURLProtocol to prevent it from intercepting remote requests
      LocalLLMURLProtocol.disableLocalLLMMode()
      URLProtocol.unregisterClass(LocalLLMURLProtocol.self)
      
      // Use standard AGUI_Adapter for remote mode
      let adapter = AGUI_Adapter(
        baseEventURL: AppConfig.defaultServerURL,
        connectionMode: .postStream
      )
      runtime.setNetworkAdapter(adapter)
      print("✅ [SceneDelegate] Remote adapter configured")
      print("   URLProtocol unregistered, using remote server: \(AppConfig.defaultServerURL)")
    }
  }
  
  /// Get model directory - checks bundle first, then documents
  private func getModelDirectory() -> URL? {
    // Check for bundled model first (for development)
    if AppConfig.preferBundledModel {
      print("🔍 [SceneDelegate] Checking for bundled model (preferBundledModel=true)...")
      if let bundleModelDir = getBundledModelDirectory() {
        print("🔍 [SceneDelegate] Checking bundled model availability at: \(bundleModelDir.path)")
        if isModelAvailable(at: bundleModelDir) {
          print("📦 [SceneDelegate] Using bundled model from app bundle")
          return bundleModelDir
        } else {
          print("⚠️ [SceneDelegate] Bundled model directory exists but files not available")
          let files = try? FileManager.default.contentsOfDirectory(atPath: bundleModelDir.path)
          print("   Files in directory: \(files ?? [])")
          // Check if files exist directly in bundle root
          if let bundlePath = Bundle.main.resourceURL {
            let allFiles = try? FileManager.default.contentsOfDirectory(atPath: bundlePath.path)
            print("   All files in bundle root (first 30): \(Array((allFiles ?? []).prefix(30)))")
          }
        }
      } else {
        print("⚠️ [SceneDelegate] Could not get bundled model directory")
      }
    } else {
      print("ℹ️ [SceneDelegate] preferBundledModel=false, skipping bundle check")
    }
    
    // Fall back to documents directory (downloaded model)
    // Model file is placed directly in models/ directory, not in a subdirectory
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let documentsModelDir = documentsDir.appendingPathComponent("models")
    print("🔍 [SceneDelegate] Checking documents model at: \(documentsModelDir.path)")
    if isModelAvailable(at: documentsModelDir) {
      print("📦 [SceneDelegate] Using model from documents directory")
      return documentsModelDir
    }
    
    print("❌ [SceneDelegate] Model not found in bundle or documents")
    return nil
  }
  
  /// Get bundled model directory from app bundle
  /// The build script copies the model file to Bundle/Models/gemma-3-270m-it-int8.task
  private func getBundledModelDirectory() -> URL? {
    guard let bundlePath = Bundle.main.resourceURL else {
      print("⚠️ [SceneDelegate] Could not get bundle resource URL")
      return nil
    }
    
    // The build script copies the .task file to Models/ directory in the bundle
    // Model file is at: Bundle/Models/gemma-3-270m-it-int8.task
    // So the model directory is: Bundle/Models/
    let modelsDir = bundlePath.appendingPathComponent("Models")
    
    // Check if Models directory exists and contains the model file
    if FileManager.default.fileExists(atPath: modelsDir.path) {
      let modelFilePath = modelsDir.appendingPathComponent("\(AppConfig.localModelFileName).task")
      if FileManager.default.fileExists(atPath: modelFilePath.path) {
        print("✅ [SceneDelegate] Found bundled model at: \(modelsDir.path)")
        return modelsDir
      } else {
        print("⚠️ [SceneDelegate] Models directory exists but model file not found")
        print("   Expected: \(modelFilePath.path)")
        if let files = try? FileManager.default.contentsOfDirectory(atPath: modelsDir.path) {
          print("   Files in Models/: \(files)")
        }
      }
    }
    
    // Fallback: Check bundle root (for legacy compatibility)
    let bundleRootModelPath = bundlePath.appendingPathComponent("\(AppConfig.localModelFileName).task")
    if FileManager.default.fileExists(atPath: bundleRootModelPath.path) {
      print("✅ [SceneDelegate] Found bundled model in bundle root (legacy location)")
      return bundlePath
    }
    
    print("⚠️ [SceneDelegate] Bundled model not found")
    print("   Bundle resource URL: \(bundlePath.path)")
    print("   Checked:")
    print("     - \(modelsDir.path)/\(AppConfig.localModelFileName).task")
    print("     - \(bundleRootModelPath.path)")
    
    // List Models directory contents for debugging
    if FileManager.default.fileExists(atPath: modelsDir.path),
       let files = try? FileManager.default.contentsOfDirectory(atPath: modelsDir.path) {
      print("   Models/ directory contents: \(files)")
    }
    
    return nil
  }
  
  private func getModelPath() -> URL? {
    guard let modelDir = getModelDirectory() else { return nil }
    
    // Look for .task file (MediaPipe model format)
    // Model file is placed directly in the directory, not in a subdirectory
    let taskPath = modelDir.appendingPathComponent("\(AppConfig.localModelFileName).task")
    
    if FileManager.default.fileExists(atPath: taskPath.path) {
      return taskPath
    }
    
    // If modelDir is from bundle, also check bundle root as fallback
    // (for backward compatibility with different bundle structures)
    // Note: Don't append "Models" again since modelDir might already be bundlePath/Models
    if modelDir.path.contains("Bundle") || modelDir.path.contains(".app"), let bundlePath = Bundle.main.resourceURL {
      // Check bundle root directly (legacy location)
      let bundleRootTaskPath = bundlePath.appendingPathComponent("\(AppConfig.localModelFileName).task")
      if FileManager.default.fileExists(atPath: bundleRootTaskPath.path) {
        return bundleRootTaskPath
      }
    }
    
    return nil
  }
  
  /// Check if model is available at given directory
  /// Only checks the specified directory, not the bundle (to avoid false positives)
  private func isModelAvailable(at modelDir: URL) -> Bool {
    // Check for .task file (MediaPipe model format)
    // Model file is placed directly in the directory, not in a subdirectory
    let taskPath = modelDir.appendingPathComponent("\(AppConfig.localModelFileName).task")
    
    if FileManager.default.fileExists(atPath: taskPath.path) {
      return true
    }
    
    // Don't check bundle here - only check the specified location
    // This prevents false positives when checking documents directory
    return false
  }
  
  /// Check if model is downloaded (in documents or bundle)
  private func isModelDownloaded() -> Bool {
    guard let modelDir = getModelDirectory() else { return false }
    return isModelAvailable(at: modelDir)
  }
  
  private func downloadModel(to destinationDir: URL, completion: @escaping (Bool) -> Void) {
    let modelFilePath = destinationDir.appendingPathComponent("\(AppConfig.localModelFileName).task")
    
    print("🔍 [SceneDelegate] Checking for model file at: \(modelFilePath.path)")
    
    // Check if model file already exists at the destination
    if FileManager.default.fileExists(atPath: modelFilePath.path) {
      print("✅ [SceneDelegate] Model file already exists at destination")
      print("   File path: \(modelFilePath.path)")
      completion(true)
      return
    }
    
    // Also check in bundle Models directory as fallback
    if let bundlePath = Bundle.main.resourceURL {
      let bundleTaskPath = bundlePath.appendingPathComponent("Models").appendingPathComponent("\(AppConfig.localModelFileName).task")
      if FileManager.default.fileExists(atPath: bundleTaskPath.path) {
        print("✅ [SceneDelegate] Model file found in bundle")
        print("   File path: \(bundleTaskPath.path)")
        // Copy from bundle to destination if needed
        do {
          try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)
          
          // Remove existing file if present (same as download path)
          // This handles cases where file was previously downloaded or partially copied
          if FileManager.default.fileExists(atPath: modelFilePath.path) {
            try FileManager.default.removeItem(at: modelFilePath)
            print("ℹ️  [SceneDelegate] Removed existing file before copying from bundle")
          }
          
          try FileManager.default.copyItem(at: bundleTaskPath, to: modelFilePath)
          print("✅ [SceneDelegate] Copied model from bundle to destination")
          completion(true)
          return
        } catch {
          print("⚠️ [SceneDelegate] Failed to copy model from bundle: \(error)")
        }
      }
    }
    
    // Model file not found - attempt to download if URL is configured
    guard let downloadURLString = AppConfig.modelDownloadURL,
          let downloadURL = URL(string: downloadURLString) else {
      print("❌ [SceneDelegate] Model file not found and no download URL configured")
      print("ℹ️  [SceneDelegate] MediaPipe models (.task files) should be manually placed in the Models directory")
      print("   Expected location: \(modelFilePath.path)")
      print("   To enable automatic download, set AppConfig.modelDownloadURL")
      print("   Please ensure the model file is present before using local mode")
      completion(false)
      return
    }
    
    // Download the model file
    print("📥 [SceneDelegate] Starting model download from: \(downloadURLString)")
    print("   Destination: \(modelFilePath.path)")
    
    // Check available storage (need at least 500MB for 290MB model)
    if let availableSpace = getAvailableStorageSpace(), availableSpace < 500_000_000 {
      print("❌ [SceneDelegate] Insufficient storage space: \(availableSpace / 1_000_000)MB available, need at least 500MB")
      completion(false)
      return
    }
    
    // Create download session and store it to keep it alive during download
    // URLSession must remain alive for the duration of the download task
    let session = URLSession(configuration: .default)
    self.downloadSession = session  // Store session to prevent deallocation
    
    let downloadTask = session.downloadTask(with: downloadURL) { [weak self] tempLocation, response, error in
      guard let self = self else {
        completion(false)
        return
      }
      
      // Clear the session reference after download completes
      self.downloadSession = nil
      
      if let error = error {
        print("❌ [SceneDelegate] Download failed: \(error.localizedDescription)")
        completion(false)
        return
      }
      
      guard let tempLocation = tempLocation else {
        print("❌ [SceneDelegate] Download failed: No temporary file location")
        completion(false)
        return
      }
      
      // Move downloaded file to destination
      do {
        // Create destination directory if needed
        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)
        
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: modelFilePath.path) {
          try FileManager.default.removeItem(at: modelFilePath)
        }
        
        // Move downloaded file to destination
        try FileManager.default.moveItem(at: tempLocation, to: modelFilePath)
        
        print("✅ [SceneDelegate] Model downloaded successfully")
        print("   File path: \(modelFilePath.path)")
        if let fileSize = try? FileManager.default.attributesOfItem(atPath: modelFilePath.path)[.size] as? Int64 {
          print("   File size: \(fileSize / 1_000_000)MB")
        }
        
        DispatchQueue.main.async {
          completion(true)
        }
      } catch {
        print("❌ [SceneDelegate] Failed to move downloaded file: \(error.localizedDescription)")
        DispatchQueue.main.async {
          completion(false)
        }
      }
    }
    
    // Start download
    downloadTask.resume()
    print("⏳ [SceneDelegate] Download in progress...")
  }
  
  /// Get available storage space in bytes
  private func getAvailableStorageSpace() -> Int64? {
    guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
          let freeSpace = attributes[.systemFreeSize] as? Int64 else {
      return nil
    }
    return freeSpace
  }
  
  private func initializeAndLoadModel(modelPath: URL, runtime: NeuronRuntime) {
    // Initialize model manager if needed
    if modelManager == nil {
      modelManager = LocalLLMModelManager(modelPath: modelPath)
    }
    
    // Show loading indicator (optional - can be improved with actual UI)
    print("⏳ [SceneDelegate] Starting model load - this may take a few seconds...")
    print("   Loading MediaPipe model file - please wait...")
    print("   Model path: \(modelPath.path)")
    
    // Load model asynchronously with error handling
    modelManager?.loadModel { [weak self] result in
      guard let self = self else {
        print("⚠️ [SceneDelegate] SceneDelegate deallocated during model load")
        return
      }
      
      switch result {
      case .success:
        print("✅ [SceneDelegate] Model loaded successfully")
        
        // Enable local LLM mode in URLProtocol
        // This allows the URLProtocol to actually process requests
        if let modelManager = self.modelManager {
          LocalLLMURLProtocol.enableLocalLLMMode(modelManager: modelManager, interval: 0.1)
          print("✅ [SceneDelegate] LocalLLMURLProtocol enabled with model manager")
          print("   Model is ready to process requests")
          print("   URLProtocol.isEnabled should now be true")
        } else {
          print("❌ [SceneDelegate] Model manager is nil, cannot enable URLProtocol")
          print("   This should not happen - model loaded but manager is nil")
        }
        
        // Note: Adapter was already created in configureNetworkAdapter
        // No need to recreate it here
        
      case .failure(let error):
        print("❌ [SceneDelegate] Failed to load model: \(error)")
        print("   Error type: \(type(of: error))")
        print("   Error description: \(error.localizedDescription)")
        if let nsError = error as NSError? {
          print("   Error domain: \(nsError.domain), code: \(nsError.code)")
          print("   User info: \(nsError.userInfo)")
        }
        // Don't fallback to remote mode - let URLProtocol handle errors
        // This allows users to see the error message in the UI
        print("   URLProtocol will return error messages for requests")
      }
    }
  }
  
  func switchMode(_ mode: ConnectionMode) {
    guard let coordinator = coordinator else {
      print("❌ [SceneDelegate] Cannot switch mode: coordinator not available")
      return
    }
    print("🔄 [SceneDelegate] Switching to \(mode == .local ? "LOCAL" : "REMOTE") mode...")
    AppConfig.currentMode = mode
    configureNetworkAdapter(runtime: coordinator.runtime, mode: mode)
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
  }
}
