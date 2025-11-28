import UIKit
import FinClipChatKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  var coordinator: ChatKitCoordinator?
  var modelManager: LocalLLMModelManager?
  private var modelDownloader: ModelDownloader?

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
        let documentsModelDir = documentsDir.appendingPathComponent("models").appendingPathComponent(AppConfig.localModelFileName)
        
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
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let documentsModelDir = documentsDir.appendingPathComponent("models").appendingPathComponent(AppConfig.localModelFileName)
    print("🔍 [SceneDelegate] Checking documents model at: \(documentsModelDir.path)")
    if isModelAvailable(at: documentsModelDir) {
      print("📦 [SceneDelegate] Using model from documents directory")
      return documentsModelDir
    }
    
    print("❌ [SceneDelegate] Model not found in bundle or documents")
    return nil
  }
  
  /// Get bundled model directory from app bundle
  private func getBundledModelDirectory() -> URL? {
    guard let bundlePath = Bundle.main.resourceURL else {
      print("⚠️ [SceneDelegate] Could not get bundle resource URL")
      return nil
    }
    
    // Try different possible paths for the model in the bundle
    // XcodeGen might copy files to bundle root or to Models/ subdirectory
    // Based on bundle contents, files appear to be in bundle root
    let possiblePaths = [
      bundlePath, // Bundle root (files are here based on logs)
      bundlePath.appendingPathComponent("Models").appendingPathComponent(AppConfig.localModelFileName), // In Models subfolder
      bundlePath.appendingPathComponent(AppConfig.localModelFileName), // Direct subdirectory in bundle root
      bundlePath.appendingPathComponent("gemma-3-270m-it-4bit"), // Explicit name
      // Also try with lowercase "models" in case of case sensitivity issues
      bundlePath.appendingPathComponent("models").appendingPathComponent(AppConfig.localModelFileName),
    ]
    
    for modelDir in possiblePaths {
      print("🔍 [SceneDelegate] Checking bundled model at: \(modelDir.path)")
      let exists = FileManager.default.fileExists(atPath: modelDir.path)
      print("   Directory exists: \(exists)")
      
      // Check if this is a directory or if files are directly in bundle root
      var isDirectory: ObjCBool = false
      if FileManager.default.fileExists(atPath: modelDir.path, isDirectory: &isDirectory) {
        if isDirectory.boolValue {
          // It's a directory, check contents
          if let files = try? FileManager.default.contentsOfDirectory(atPath: modelDir.path) {
            print("   Files in directory: \(files.prefix(10))")
            if isModelAvailable(at: modelDir) {
              print("✅ [SceneDelegate] Found bundled model at: \(modelDir.path)")
              return modelDir
            } else {
              print("⚠️ [SceneDelegate] Directory exists but model files not complete")
            }
          }
        } else {
          // It's a file, not a directory - skip
          print("   Path exists but is a file, not a directory")
        }
      } else {
        // Path doesn't exist - check if model files are directly in bundle root
        if modelDir == bundlePath {
          print("   Checking bundle root for model files directly...")
          let configFile = bundlePath.appendingPathComponent("config.json")
          let modelFile = bundlePath.appendingPathComponent("model.safetensors")
          let tokenizerFile = bundlePath.appendingPathComponent("tokenizer.json")
          
          let hasConfig = FileManager.default.fileExists(atPath: configFile.path)
          let hasModel = FileManager.default.fileExists(atPath: modelFile.path)
          let hasTokenizer = FileManager.default.fileExists(atPath: tokenizerFile.path)
          
          print("   config.json exists: \(hasConfig)")
          print("   model.safetensors exists: \(hasModel)")
          print("   tokenizer.json exists: \(hasTokenizer)")
          
          if hasConfig && hasModel && hasTokenizer {
            print("✅ [SceneDelegate] Found model files directly in bundle root")
            return bundlePath
          }
        }
      }
    }
    
    print("⚠️ [SceneDelegate] Bundled model not found in any expected location")
    print("   Bundle resource URL: \(bundlePath.path)")
    print("   Tried paths:")
    for path in possiblePaths {
      let exists = FileManager.default.fileExists(atPath: path.path)
      print("     - \(path.path) [exists: \(exists)]")
    }
    
    // List all files in bundle root for debugging
    if let bundleContents = try? FileManager.default.contentsOfDirectory(atPath: bundlePath.path) {
      print("   Bundle root contents (first 50): \(Array(bundleContents.prefix(50)))")
      
      // Check for actual model files (not just metadata)
      let modelFiles = bundleContents.filter { file in
        file == "config.json" || 
        file == "model.safetensors" || 
        file == "tokenizer.json" ||
        file == "tokenizer.model" ||
        file.hasPrefix("gemma-3-270m-it-4bit")
      }
      if !modelFiles.isEmpty {
        print("   Found potential model files: \(modelFiles)")
      }
    }
    
    // Also check if Models directory exists
    let modelsDir = bundlePath.appendingPathComponent("Models")
    if FileManager.default.fileExists(atPath: modelsDir.path) {
      print("   Models directory exists at: \(modelsDir.path)")
      if let modelsContents = try? FileManager.default.contentsOfDirectory(atPath: modelsDir.path) {
        print("   Models directory contents: \(modelsContents)")
      }
    } else {
      print("   Models directory does NOT exist at: \(modelsDir.path)")
    }
    
    // Check if files are directly in bundle root (without subdirectory)
    print("   Checking for model files directly in bundle root...")
    let directConfig = bundlePath.appendingPathComponent("config.json")
    let directModel = bundlePath.appendingPathComponent("model.safetensors")
    let directTokenizer = bundlePath.appendingPathComponent("tokenizer.json")
    print("     config.json: \(FileManager.default.fileExists(atPath: directConfig.path))")
    print("     model.safetensors: \(FileManager.default.fileExists(atPath: directModel.path))")
    print("     tokenizer.json: \(FileManager.default.fileExists(atPath: directTokenizer.path))")
    
    return nil
  }
  
  private func getModelPath() -> URL? {
    guard let modelDir = getModelDirectory() else { return nil }
    
    // Look for .task file (MediaPipe model format)
    let taskPath = modelDir.appendingPathComponent("\(AppConfig.localModelFileName).task")
    
    if FileManager.default.fileExists(atPath: taskPath.path) {
      return taskPath
    }
    
    // Also check if .task file is directly in Models directory
    if let bundlePath = Bundle.main.resourceURL {
      let bundleTaskPath = bundlePath.appendingPathComponent("Models").appendingPathComponent("\(AppConfig.localModelFileName).task")
      if FileManager.default.fileExists(atPath: bundleTaskPath.path) {
        return bundleTaskPath
      }
    }
    
    return nil
  }
  
  /// Check if model is available at given directory
  private func isModelAvailable(at modelDir: URL) -> Bool {
    // Check for .task file (MediaPipe model format)
    let taskPath = modelDir.appendingPathComponent("\(AppConfig.localModelFileName).task")
    
    if FileManager.default.fileExists(atPath: taskPath.path) {
      return true
    }
    
    // Also check if .task file is directly in Models directory
    if let bundlePath = Bundle.main.resourceURL {
      let bundleTaskPath = bundlePath.appendingPathComponent("Models").appendingPathComponent("\(AppConfig.localModelFileName).task")
      if FileManager.default.fileExists(atPath: bundleTaskPath.path) {
        return true
      }
    }
    
    return false
  }
  
  /// Check if model is downloaded (in documents or bundle)
  private func isModelDownloaded() -> Bool {
    guard let modelDir = getModelDirectory() else { return false }
    return isModelAvailable(at: modelDir)
  }
  
  private func downloadModel(to destinationDir: URL, completion: @escaping (Bool) -> Void) {
    // MediaPipe models are .task files that should be manually placed in the Models directory
    // For now, we'll just check if the file exists
    print("ℹ️  [SceneDelegate] MediaPipe models (.task files) should be manually placed in the Models directory")
    print("   Expected location: \(destinationDir.appendingPathComponent("\(AppConfig.localModelFileName).task").path)")
    print("   Please ensure the model file is present before using local mode")
    completion(false)
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
