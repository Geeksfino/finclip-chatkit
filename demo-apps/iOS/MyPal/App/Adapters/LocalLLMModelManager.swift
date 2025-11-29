//
//  LocalLLMModelManager.swift
//  MyPal
//
//  Manages loading and inference with Gemma 270M using Google MediaPipe LLM Inference API
//

import Foundation
import MediaPipeTasksGenAI

enum ModelManagerError: Error, LocalizedError {
  case modelNotLoaded
  case modelLoadFailed(Error)
  case inferenceFailed(Error)
  
  var errorDescription: String? {
    switch self {
    case .modelNotLoaded:
      return "Model is not loaded"
    case .modelLoadFailed(let error):
      return "Failed to load model: \(error.localizedDescription)"
    case .inferenceFailed(let error):
      return "Inference failed: \(error.localizedDescription)"
    }
  }
}

class LocalLLMModelManager {
  private var isModelLoaded = false
  private let modelPath: URL
  private var llmInference: LlmInference?
  
  init(modelPath: URL) {
    self.modelPath = modelPath
  }
  
  /// Load the MediaPipe LLM model
  /// - Parameter completion: Completion handler with success/failure
  func loadModel(completion: @escaping (Result<Void, Error>) -> Void) {
    // Run on background thread to prevent blocking
    Task.detached(priority: .userInitiated) { [weak self] in
      guard let self = self else {
        await MainActor.run {
          completion(.failure(ModelManagerError.modelLoadFailed(
            NSError(domain: "LocalLLMModelManager", code: -999,
                   userInfo: [NSLocalizedDescriptionKey: "Model manager deallocated"])
          )))
        }
        return
      }
      
      do {
        // Check if model file exists
        guard FileManager.default.fileExists(atPath: self.modelPath.path) else {
          throw ModelManagerError.modelLoadFailed(
            NSError(domain: "LocalLLMModelManager", code: -1,
                   userInfo: [NSLocalizedDescriptionKey: "Model file not found at \(self.modelPath.path). Please ensure the model file is in the Models directory."])
          )
        }
        
        print("📦 [LocalLLMModelManager] Loading model from: \(self.modelPath.path)")
        
        // Configure LLM Inference options
        // Note: LlmInference.Options is for model initialization
        // Session options (temperature, topk, etc.) are set when creating a session
        // Use 'var' instead of 'let' to allow property modification
        var options = LlmInference.Options(modelPath: self.modelPath.path)
        options.maxTokens = AppConfig.localModelContextSize
        options.maxTopk = 40
        
        print("📋 [LocalLLMModelManager] Model options configured:")
        print("   Model path: \(options.modelPath)")
        print("   Max tokens: \(options.maxTokens)")
        print("   Max top-k: \(options.maxTopk)")
        
        // Initialize LLM Inference
        print("🔄 [LocalLLMModelManager] Initializing LlmInference...")
        let llmInference = try LlmInference(options: options)
        self.llmInference = llmInference
        
        self.isModelLoaded = true
        print("✅ [LocalLLMModelManager] Model loaded successfully")
        
        // Call completion on main thread
        await MainActor.run {
          completion(.success(()))
        }
      } catch {
        print("❌ [LocalLLMModelManager] Model loading failed: \(error)")
        print("   Error type: \(type(of: error))")
        print("   Error description: \(error.localizedDescription)")
        if let nsError = error as NSError? {
          print("   Error domain: \(nsError.domain), code: \(nsError.code)")
          print("   User info: \(nsError.userInfo)")
        }
        await MainActor.run {
          completion(.failure(ModelManagerError.modelLoadFailed(error)))
        }
      }
    }
  }
  
  /// Generate response from local LLM
  /// - Parameters:
  ///   - prompt: User's input message
  ///   - contextItems: Attached context items (for reference)
  ///   - selectedTools: Selected tools (for reference)
  ///   - completion: Completion handler with generated response or error
  func generateResponse(
    prompt: String,
    contextItems: [[String: Any]] = [],
    selectedTools: [[String: Any]] = [],
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    guard isModelLoaded, let llmInference = self.llmInference else {
      completion(.failure(ModelManagerError.modelNotLoaded))
      return
    }
    
    Task {
      do {
        // Format prompt for Gemma model
        let formattedPrompt = self.formatPrompt(userMessage: prompt, contextItems: contextItems, selectedTools: selectedTools)
        
        print("🤖 [LocalLLMModelManager] Generating response for prompt: \(formattedPrompt.prefix(100))...")
        
        // Generate response using MediaPipe LLM Inference API
        // Run on background thread to avoid blocking
        let response = try await Task.detached(priority: .userInitiated) {
          return try llmInference.generateResponse(inputText: formattedPrompt)
        }.value
        
        print("✅ [LocalLLMModelManager] Generated response: \(response.prefix(100))...")
        
        await MainActor.run {
          completion(.success(response))
        }
      } catch {
        print("❌ [LocalLLMModelManager] Inference failed: \(error)")
        await MainActor.run {
          completion(.failure(ModelManagerError.inferenceFailed(error)))
        }
      }
    }
  }
  
  /// Format prompt for Gemma model
  private func formatPrompt(userMessage: String, contextItems: [[String: Any]], selectedTools: [[String: Any]]) -> String {
    var prompt = userMessage
    
    // Add context information if available
    if !contextItems.isEmpty {
      prompt += "\n\n[Context attached: \(contextItems.count) item(s)]"
    }
    
    // Add tool information if available
    if !selectedTools.isEmpty {
      let toolNames = selectedTools.compactMap { $0["displayName"] as? String }
      prompt += "\n\n[Tools available: \(toolNames.joined(separator: ", "))]"
    }
    
    return prompt
  }
  
  /// Unload the model to free memory
  func unloadModel() {
    llmInference = nil
    isModelLoaded = false
    print("🧹 [LocalLLMModelManager] Model unloaded")
  }
  
  /// Check if model is loaded
  var isLoaded: Bool {
    return isModelLoaded
  }
}
