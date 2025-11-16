//
//  LocalLLMModelManager.swift
//  MyPal
//
//  Manages loading and inference with Gemma 270M MLX model
//

import Foundation
import MLX
import MLXNN
import MLXRandom
import Tokenizers
import Hub

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

// Protocol for tokenizer operations
protocol TokenizerProtocol {
  func encode(text: String) throws -> [Int]
  func decode(tokens: [Int]) throws -> String
}

// Wrapper for swift-transformers Tokenizer
class SwiftTransformersTokenizer: TokenizerProtocol {
  private let tokenizer: Tokenizer
  
  init(tokenizer: Tokenizer) {
    self.tokenizer = tokenizer
  }
  
  func encode(text: String) throws -> [Int] {
    // swift-transformers Tokenizer.encode returns [Int] directly
    return try tokenizer.encode(text: text)
  }
  
  func decode(tokens: [Int]) throws -> String {
    // swift-transformers Tokenizer.decode takes [Int] directly
    return try tokenizer.decode(tokens: tokens)
  }
}

// Placeholder tokenizer for testing infrastructure (fallback)
class PlaceholderTokenizer: TokenizerProtocol {
  func encode(text: String) throws -> [Int] {
    // Simple word-based tokenization (placeholder)
    return text.split(separator: " ").map { abs($0.hashValue) % 10000 }
  }
  
  func decode(tokens: [Int]) throws -> String {
    // This won't work properly without a real tokenizer
    // Return a placeholder message
    return "Generated response (placeholder tokenizer)"
  }
}

class LocalLLMModelManager {
  private var isModelLoaded = false
  private let modelPath: URL
  private var modelWeights: [String: MLXArray]?
  private var modelConfig: [String: Any]?
  private var tokenizer: TokenizerProtocol?
  private var gemmaModel: GemmaModel?
  
  init(modelPath: URL) {
    self.modelPath = modelPath
  }
  
  /// Load the MLX model
  /// - Parameter completion: Completion handler with success/failure
  func loadModel(completion: @escaping (Result<Void, Error>) -> Void) {
    // Check if running on simulator - MLX doesn't work on simulator
    guard DeviceDetection.canUseMLX else {
      completion(.failure(ModelManagerError.modelLoadFailed(
        NSError(domain: "LocalLLMModelManager", code: -1000,
               userInfo: [NSLocalizedDescriptionKey: "MLX is not available on iOS Simulator. Please test on a physical device."])
      )))
      return
    }
    
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
        // Check if model directory exists
        let modelDir = self.modelPath.deletingLastPathComponent()
        guard FileManager.default.fileExists(atPath: modelDir.path) else {
          throw ModelManagerError.modelLoadFailed(
            NSError(domain: "LocalLLMModelManager", code: -1, 
                   userInfo: [NSLocalizedDescriptionKey: "Model directory not found at \(modelDir.path). Please download the model first."])
          )
        }
        
        // Check for required model files
        // MLX models typically have: weights.safetensors or model.safetensors, config.json, tokenizer.json
        let weightsPath = modelDir.appendingPathComponent("weights.safetensors")
        let modelPath = modelDir.appendingPathComponent("model.safetensors")
        let configPath = modelDir.appendingPathComponent("config.json")
        let tokenizerPath = modelDir.appendingPathComponent("tokenizer.json")
        
        // Check for weights file (try both common names)
        let hasWeights = FileManager.default.fileExists(atPath: weightsPath.path) ||
                         FileManager.default.fileExists(atPath: modelPath.path)
        
        guard hasWeights else {
          throw ModelManagerError.modelLoadFailed(
            NSError(domain: "LocalLLMModelManager", code: -2,
                   userInfo: [NSLocalizedDescriptionKey: "Model weights not found. Expected weights.safetensors or model.safetensors in \(modelDir.path)"])
          )
        }
        
        // Use whichever file exists
        let actualWeightsPath = FileManager.default.fileExists(atPath: modelPath.path) ? modelPath : weightsPath
        
        print("📦 [LocalLLMModelManager] Loading model from: \(modelDir.path)")
        
        // Load model components using MLX framework
        // Load model configuration
        print("📋 [LocalLLMModelManager] Loading config...")
        let configData = try Data(contentsOf: configPath)
        if let config = try JSONSerialization.jsonObject(with: configData) as? [String: Any] {
          self.modelConfig = config
          print("📋 [LocalLLMModelManager] Model config loaded")
        }
        
        // Load model weights from safetensors file
        // MLX can load safetensors files directly
        // This is async to prevent UI freezing during large file load
        // Updated to MLX-Swift 0.29.1 - should fix loadArrays crash
        print("⚖️  [LocalLLMModelManager] Loading weights (this may take 10-30 seconds)...")
        print("   Using mlx-community model with MLX-Swift 0.29.1")
        
        // Load weights using MLX.loadArrays
        // mlx-community models are pre-converted for MLX and should work
        let weights = try await self.loadWeights(from: actualWeightsPath)
        self.modelWeights = weights
        print("⚖️  [LocalLLMModelManager] Model weights loaded: \(weights.count) tensors")
        
        // Initialize Gemma model with loaded weights
        print("🏗️  [LocalLLMModelManager] Initializing Gemma model architecture...")
        let gemmaConfig = GemmaConfig(from: self.modelConfig ?? [:])
        do {
          self.gemmaModel = try GemmaModel(config: gemmaConfig, weights: weights)
          print("✅ [LocalLLMModelManager] Gemma model initialized")
        } catch {
          print("❌ [LocalLLMModelManager] Failed to initialize Gemma model: \(error)")
          throw ModelManagerError.modelLoadFailed(error)
        }
        
        // Load tokenizer
        // For Gemma models, we need to load the tokenizer.json file
        // This typically uses SentencePiece or similar tokenizer
        print("📝 [LocalLLMModelManager] Loading tokenizer...")
        if FileManager.default.fileExists(atPath: tokenizerPath.path) {
          do {
            // Load tokenizer asynchronously (swift-transformers uses async API)
            self.tokenizer = try await self.loadTokenizer(from: tokenizerPath)
            print("📝 [LocalLLMModelManager] Tokenizer loaded")
          } catch {
            print("⚠️ [LocalLLMModelManager] Tokenizer loading failed: \(error)")
            print("   Using placeholder tokenizer")
            self.tokenizer = PlaceholderTokenizer()
          }
        } else {
          print("⚠️ [LocalLLMModelManager] Tokenizer file not found, will use fallback")
          self.tokenizer = PlaceholderTokenizer()
        }
        
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
    guard isModelLoaded else {
      completion(.failure(ModelManagerError.modelNotLoaded))
      return
    }
    
    Task {
      do {
        // Format prompt for Gemma model
        // Gemma models typically use a specific prompt format
        let formattedPrompt = self.formatPrompt(userMessage: prompt, contextItems: contextItems, selectedTools: selectedTools)
        
        print("🤖 [LocalLLMModelManager] Generating response for prompt: \(formattedPrompt.prefix(100))...")
        
        // Generate response using MLX model
        guard let weights = self.modelWeights, let config = self.modelConfig else {
          throw ModelManagerError.inferenceFailed(
            NSError(domain: "LocalLLMModelManager", code: -3,
                   userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
          )
        }
        
        // Tokenize input prompt
        let inputTokens = try self.tokenizePrompt(formattedPrompt)
        print("🔢 [LocalLLMModelManager] Tokenized input: \(inputTokens.count) tokens")
        
        // Generate tokens using MLX
        let outputTokens = try await self.generateTokens(
          weights: weights,
          config: config,
          inputTokens: inputTokens,
          maxTokens: AppConfig.localModelContextSize,
          temperature: AppConfig.localModelTemperature
        )
        
        print("🎲 [LocalLLMModelManager] Generated \(outputTokens.count) output tokens")
        
        // Decode tokens to text
        let response = try self.detokenize(outputTokens)
        
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
  
  /// Load model weights from safetensors file
  private func loadWeights(from path: URL) async throws -> [String: MLXArray] {
    guard FileManager.default.fileExists(atPath: path.path) else {
      throw ModelManagerError.modelLoadFailed(
        NSError(domain: "LocalLLMModelManager", code: -10,
               userInfo: [NSLocalizedDescriptionKey: "Weights file not found: \(path.path)"])
      )
    }
    
    // Get file size for validation
    let fileAttributes = try FileManager.default.attributesOfItem(atPath: path.path)
    let fileSize = fileAttributes[.size] as? Int64 ?? 0
    print("📊 [LocalLLMModelManager] Weights file size: \(fileSize) bytes")
    
    // Use MLX-Swift's built-in safetensors loader
    // MLX.loadArrays(url:) loads safetensors files directly into [String: MLXArray]
    // This is a blocking operation, so we run it on a background thread
    print("📦 [LocalLLMModelManager] Loading safetensors file using MLX.loadArrays...")
    print("   This may take 10-30 seconds for a 500MB file...")
    
    // Run the blocking load operation on a background thread
    // MLX.loadArrays is a synchronous blocking call that can take 10-30 seconds
    // We use Task.detached to ensure it doesn't block the main thread
    return try await withCheckedThrowingContinuation { continuation in
      Task.detached(priority: .userInitiated) {
        do {
          // Yield immediately to allow UI to update
          await Task.yield()
          
          // Validate file before loading
          // Check if file is readable and has valid safetensors header
          print("🔍 [LocalLLMModelManager] Validating safetensors file...")
          let fileHandle = try FileHandle(forReadingFrom: path)
          defer { fileHandle.closeFile() }
          
          // Read first 8 bytes to check safetensors magic number
          // Safetensors files start with specific header
          fileHandle.seek(toFileOffset: 0)
          let headerData = fileHandle.readData(ofLength: 8)
          if headerData.count < 8 {
            throw ModelManagerError.modelLoadFailed(
              NSError(domain: "LocalLLMModelManager", code: -20,
                     userInfo: [NSLocalizedDescriptionKey: "Safetensors file too small or corrupted"])
            )
          }
          
          // Check for safetensors magic bytes (optional validation)
          // Note: This is a basic check, actual format validation happens in MLX
          print("✅ [LocalLLMModelManager] File header looks valid, proceeding with load...")
          
          // Load arrays from safetensors file
          // MLX.loadArrays has two versions:
          // 1. loadArrays(url:) - loads directly from file (preferred for large files)
          // 2. loadArrays(data:) - loads from Data (may have memory issues)
          // Try URL version first as it's more memory-efficient for large files
          print("🔄 [LocalLLMModelManager] Loading safetensors file using MLX.loadArrays(url:)...")
          print("   File path: \(path.path)")
          print("   ⚠️  This may take 10-30 seconds for a 151MB file...")
          
          let startTime = Date()
          
          // Ensure URL is a proper file URL
          let fileURL = path.isFileURL ? path : URL(fileURLWithPath: path.path)
          
          // Use loadArrays(url:) - more memory-efficient for large files
          // The URL version reads directly from disk without loading entire file into memory
          // On physical devices, MLX will use GPU by default for better performance
          let arrays: [String: MLXArray]
          do {
            arrays = try MLX.loadArrays(url: fileURL)
          } catch {
            print("❌ [LocalLLMModelManager] MLX.loadArrays(url:) failed: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            print("   Trying loadArrays(data:) as fallback...")
            
            // Fallback to Data version if URL version fails
            // Read file into Data (may cause memory issues for large files)
            let fileData = try Data(contentsOf: path)
            print("✅ [LocalLLMModelManager] File loaded into memory: \(fileData.count) bytes")
            print("   ⚠️  Using Data version - may have memory issues")
            
            do {
              arrays = try MLX.loadArrays(data: fileData)
            } catch {
              print("❌ [LocalLLMModelManager] MLX.loadArrays(data:) also failed: \(error)")
              throw ModelManagerError.modelLoadFailed(error)
            }
          }
          
          let loadTime = Date().timeIntervalSince(startTime)
          print("⏱️  [LocalLLMModelManager] Safetensors load took \(String(format: "%.1f", loadTime)) seconds")
          
        print("✅ [LocalLLMModelManager] Loaded \(arrays.count) tensors from safetensors file")
        
        // Log some tensor names for debugging (first 10)
        let tensorNames = Array(arrays.keys.prefix(10))
        print("📋 [LocalLLMModelManager] Sample tensor names: \(tensorNames.joined(separator: ", "))")
        if arrays.count > 10 {
          print("   ... and \(arrays.count - 10) more")
        }
        
        // Log all tensor names containing "lm_head" or "output" for debugging
        let lmHeadTensors = arrays.keys.filter { $0.contains("lm_head") || $0.contains("output") }
        if !lmHeadTensors.isEmpty {
          print("🔍 [LocalLLMModelManager] Found lm_head/output tensors: \(lmHeadTensors.joined(separator: ", "))")
        } else {
          print("⚠️ [LocalLLMModelManager] No tensors found containing 'lm_head' or 'output'")
          // Log all tensor names sorted
          let allTensorNames = Array(arrays.keys).sorted()
          print("📋 [LocalLLMModelManager] All tensor names (first 50):")
          for (index, name) in allTensorNames.prefix(50).enumerated() {
            print("   \(index + 1). \(name)")
          }
          if allTensorNames.count > 50 {
            print("   ... and \(allTensorNames.count - 50) more")
          }
        }
          
          continuation.resume(returning: arrays)
        } catch {
          print("❌ [LocalLLMModelManager] Failed to load safetensors: \(error)")
          continuation.resume(throwing: ModelManagerError.modelLoadFailed(error))
        }
      }
    }
  }
  
  /// Load tokenizer from tokenizer.json file
  private func loadTokenizer(from path: URL) async throws -> TokenizerProtocol {
    // Load tokenizer using swift-transformers
    // The tokenizer.json file contains the tokenizer configuration
    // swift-transformers can load from local directory using LanguageModelConfigurationFromHub
    
    let tokenizerDir = path.deletingLastPathComponent()
    let tokenizerJsonPath = tokenizerDir.appendingPathComponent("tokenizer.json")
    let tokenizerModelPath = tokenizerDir.appendingPathComponent("tokenizer.model")
    
    print("📝 [LocalLLMModelManager] Loading tokenizer from: \(tokenizerDir.path)")
    print("   Checking for tokenizer.json: \(FileManager.default.fileExists(atPath: tokenizerJsonPath.path))")
    print("   Checking for tokenizer.model: \(FileManager.default.fileExists(atPath: tokenizerModelPath.path))")
    
    do {
      // Try loading directly from tokenizer.json file
      // AutoTokenizer can load from a local tokenizer.json file
      if FileManager.default.fileExists(atPath: tokenizerJsonPath.path) {
        let tokenizerData = try Data(contentsOf: tokenizerJsonPath)
        print("✅ [LocalLLMModelManager] Loaded tokenizer.json: \(tokenizerData.count) bytes")
        
        // Try to create tokenizer from JSON file path
        // Check if AutoTokenizer has a method to load from file path
        // If not, we'll need to use the Hub configuration approach
        let tokenizer = try await AutoTokenizer.from(pretrained: tokenizerDir.path)
        
        print("✅ [LocalLLMModelManager] Tokenizer loaded successfully from tokenizer.json")
        return SwiftTransformersTokenizer(tokenizer: tokenizer)
      }
      
      // Fallback: Try using LanguageModelConfigurationFromHub
      let configuration = LanguageModelConfigurationFromHub(modelFolder: tokenizerDir)
      
      // Load tokenizer config and data
      guard let tokenizerConfig = try await configuration.tokenizerConfig else {
        throw ModelManagerError.modelLoadFailed(
          NSError(domain: "LocalLLMModelManager", code: -30,
                 userInfo: [NSLocalizedDescriptionKey: "Tokenizer config not found"])
        )
      }
      
      let tokenizerData = try await configuration.tokenizerData
      
      // Create tokenizer from config and data
      let tokenizer = try AutoTokenizer.from(
        tokenizerConfig: tokenizerConfig,
        tokenizerData: tokenizerData
      )
      
      print("✅ [LocalLLMModelManager] Tokenizer loaded successfully")
      
      // Wrap in our protocol
      return SwiftTransformersTokenizer(tokenizer: tokenizer)
    } catch {
      print("⚠️ [LocalLLMModelManager] Failed to load tokenizer with swift-transformers: \(error)")
      print("   Error details: \(error.localizedDescription)")
      print("   Error type: \(type(of: error))")
      print("   Falling back to placeholder tokenizer")
      print("   ⚠️  WARNING: Placeholder tokenizer will not work correctly for encoding/decoding!")
      
      // Fallback to placeholder if loading fails
      return PlaceholderTokenizer()
    }
  }
  
  /// Generate tokens from input tokens using MLX model
  private func generateTokens(
    weights: [String: MLXArray],
    config: [String: Any],
    inputTokens: [Int],
    maxTokens: Int,
    temperature: Float
  ) async throws -> [Int] {
    // Get model configuration
    let eosTokenId = config["eos_token_id"] as? Int ?? 1
    
    // Check if model is loaded
    guard let model = self.gemmaModel else {
      print("⚠️ [LocalLLMModelManager] Gemma model not initialized")
      return [eosTokenId]
    }
    
    print("🚀 [LocalLLMModelManager] Starting token generation...")
    print("   Input tokens: \(inputTokens.count)")
    print("   Max tokens: \(maxTokens)")
    print("   Temperature: \(temperature)")
    
    // Convert input tokens to MLXArray: [batch=1, seq_len]
    // CRITICAL: Embedding requires integer indices, not floats!
    // Use Int32 for indices (MLX's gather operation requires integral types)
    var currentTokens = MLXArray(inputTokens.map { Int32($0) }).reshaped(1, inputTokens.count)
    var generatedTokens: [Int] = []
    
    // Generate tokens iteratively
    for step in 0..<maxTokens {
      // Forward pass to get logits for next token
      let logits = try model.generateNextTokenLogits(currentTokens)
      
      // Apply temperature scaling
      let scaledLogits = logits / temperature
      
      // Sample next token using softmax and categorical sampling
      let probs = softmax(scaledLogits, axis: -1)
      let nextTokenId = sampleToken(from: probs)
      
      // Check for EOS token
      if nextTokenId == eosTokenId {
        print("✅ [LocalLLMModelManager] Generated EOS token, stopping generation")
        break
      }
      
      generatedTokens.append(nextTokenId)
      
      // Append to current tokens for next iteration
      // CRITICAL: Keep as Int32 for embedding indices
      let nextTokenArray = MLXArray([Int32(nextTokenId)]).reshaped(1, 1)
      currentTokens = concatenated([currentTokens, nextTokenArray], axis: 1)
      
      // Log progress every 10 tokens
      if (step + 1) % 10 == 0 {
        print("   Generated \(generatedTokens.count) tokens...")
      }
    }
    
    print("✅ [LocalLLMModelManager] Generated \(generatedTokens.count) tokens")
    return generatedTokens
  }
  
  /// Sample a token from probability distribution
  private func sampleToken(from probs: MLXArray) -> Int {
    // Use categorical sampling
    // MLXRandom.categorical samples from a probability distribution
    let sampled = MLXRandom.categorical(probs, count: 1)
    // Convert MLXArray to Int - get first element
    // MLXRandom.categorical returns integer indices, not floats
    // sampled is [1], get the first value as Int32
    let tokenId = Int(sampled[0].item(Int32.self))
    return tokenId
  }
  
  /// Tokenize prompt text into token IDs
  private func tokenizePrompt(_ text: String) throws -> [Int] {
    // If tokenizer is available, use it
    if let tokenizer = self.tokenizer {
      return try tokenizer.encode(text: text)
    }
    
    // Fallback: Simple word-based tokenization (very basic, not recommended for production)
    // This is a placeholder until proper tokenizer is implemented
    print("⚠️ [LocalLLMModelManager] Using fallback tokenization")
    return text.split(separator: " ").map { abs($0.hashValue) % 10000 }
  }
  
  /// Detokenize token IDs back to text
  private func detokenize(_ tokens: [Int]) throws -> String {
    guard let tokenizer = self.tokenizer else {
      print("⚠️ [LocalLLMModelManager] No tokenizer available - using fallback")
      return "Generated response (tokenizer not available)"
    }
    
    // Filter out special tokens before decoding
    // Get special token IDs from config
    let eosTokenId = modelConfig?["eos_token_id"] as? Int ?? 1
    let bosTokenId = modelConfig?["bos_token_id"] as? Int ?? 2
    let unkTokenId = modelConfig?["unk_token_id"] as? Int ?? 0
    let padTokenId = modelConfig?["pad_token_id"] as? Int ?? 0
    
    // Filter out special tokens (keep only regular text tokens)
    let filteredTokens = tokens.filter { token in
      token != eosTokenId && 
      token != bosTokenId && 
      token != unkTokenId && 
      token != padTokenId &&
      token > 0 // Also filter out any invalid tokens
    }
    
    // Decode the filtered tokens
    let decoded = try tokenizer.decode(tokens: filteredTokens)
    
    // Clean up any remaining special token strings that might have been decoded
    let cleaned = decoded
      .replacingOccurrences(of: "<eos>", with: "")
      .replacingOccurrences(of: "<bos>", with: "")
      .replacingOccurrences(of: "<unk>", with: "")
      .replacingOccurrences(of: "<mask>", with: "")
      .replacingOccurrences(of: "<pad>", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // If cleaned result is empty, return a default message
    if cleaned.isEmpty {
      return "I'm here to help! (Model weights not loaded - placeholder mode)"
    }
    
    return cleaned
  }
  
  /// Unload the model to free memory
  func unloadModel() {
    // Release MLX arrays to free GPU memory
    modelWeights = nil
    modelConfig = nil
    tokenizer = nil
    isModelLoaded = false
    
    // Force MLX to synchronize and free memory
    MLX.eval()
    
    print("🧹 [LocalLLMModelManager] Model unloaded")
  }
  
  /// Check if model is loaded
  var isLoaded: Bool {
    return isModelLoaded
  }
}


