//
//  GemmaTestRunner.swift
//  GemmaTestAppFeature
//
//  Public API for running Gemma tests from the macOS app
//

import Foundation
import MLX
import MLXRandom

public struct GemmaTestConfig {
    public let modelPath: String
    public let prompt: String
    public let maxTokens: Int
    public let temperature: Float
    public let topK: Int
    
    public init(
        modelPath: String,
        prompt: String = "Hello",
        maxTokens: Int = 50,
        temperature: Float = 0.7,
        topK: Int = 50
    ) {
        self.modelPath = modelPath
        self.prompt = prompt
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topK = topK
    }
}

public class GemmaTestRunner {
    public init() {}
    
    @MainActor
    public func run(config: GemmaTestConfig) async throws {
        print("🚀 [GemmaTest] Starting model test")
        print("   Model path: \(config.modelPath)")
        print("   Prompt: \(config.prompt)")
        print("   Max tokens: \(config.maxTokens)")
        print("   Temperature: \(config.temperature)")
        print("")
        
        // 1. Load model using registry
        print("📦 [GemmaTest] Loading model...")
        let model = try ModelRegistry.shared.loadModel(from: config.modelPath)
        
        // Get config from the model's weights
        let (configDict, _) = try WeightLoader.loadFromDirectory(config.modelPath)
        print("✅ [GemmaTest] Model weights loaded")
        print("")
        
        // 2. Initialize model (already done by registry)
        print("🏗️  [GemmaTest] Model initialized")
        print("")
        
        // 3. Load tokenizer
        print("📝 [GemmaTest] Loading tokenizer...")
        let gemmaConfig = GemmaConfig(from: configDict)
        let tokenizer = try await TokenizerLoader.load(from: config.modelPath, config: gemmaConfig)
        print("✅ [GemmaTest] Tokenizer loaded")
        print("")
        
        // 4. Apply prompt template based on model type
        print("🔤 [GemmaTest] Preparing prompt...")
        var promptToEncode = config.prompt
        
        if model.modelType == .phi3_mini {
            // Phi-3 requires chat template format
            let promptBuilder = Phi3PromptBuilder(systemPrompt: "You are a helpful AI assistant.")
            promptToEncode = promptBuilder.buildPrompt(userMessage: config.prompt)
            print("   Phi-3 format applied:")
            print("   \(promptToEncode.replacingOccurrences(of: "\n", with: "\\n"))")
        } else {
            print("   Using raw prompt: \(config.prompt)")
        }
        print("")
        
        // 5. Encode prompt
        print("🔤 [GemmaTest] Encoding prompt...")
        var inputTokens = try tokenizer.encode(promptToEncode)
        
        // Phi-3 tokenizer config says add_bos_token: false, so don't add BOS manually
        // The tokenizer should handle special tokens automatically
        
        print("   Input tokens: \(inputTokens)")
        print("   Token count: \(inputTokens.count)")
        print("")
        
        // 5. Prime the model with the FULL prompt sequence (not token-by-token!)
        print("🤖 [GemmaTest] Generating response...")
        print("   (This may take a while)")
        print("")
        
        var generatedTokens = inputTokens
        let eosTokenId = Int32(gemmaConfig.eosTokenId)
        var cacheK: [[MLXArray?]] = []
        var cacheV: [[MLXArray?]] = []
        
        // Process FULL prompt sequence at once (critical for attention to work!)
        let promptInts = inputTokens.map { Int($0) }
        let promptTokenArray = MLXArray(promptInts).reshaped([1, inputTokens.count])
        print("   Processing prompt sequence: \(inputTokens.count) tokens")
        
        let (allLogits, newCacheK, newCacheV) = try model.forward(
            promptTokenArray,
            cacheK: nil,  // No cache initially
            cacheV: nil
        )
        cacheK = newCacheK ?? []
        cacheV = newCacheV ?? []
        
        // Extract logits for the last token: [batch, seq, vocab] -> [batch, vocab] for last position
        let seqLen = allLogits.dim(1)
        let lastLogits = allLogits[0..., (seqLen - 1)..., 0...]
            .squeezed(axes: [1])
        
        var nextLogits = lastLogits
        
        for step in 0..<config.maxTokens {
            let nextToken: Int32
            if config.temperature == 0.0 {
                nextToken = greedySample(nextLogits)
            } else {
                nextToken = topKSample(nextLogits, topK: config.topK, temperature: config.temperature)
            }
            
            generatedTokens.append(nextToken)
            
            if nextToken == eosTokenId {
                print("   [Step \(step)] EOS token generated, stopping")
                break
            }
            
            if step % 5 == 0 || step == config.maxTokens - 1 {
                let decoded = try tokenizer.decode([nextToken])
                print(decoded, terminator: "")
                fflush(stdout)
            }
            
            // Generate next token using KV cache (single token, but with full context from cache)
            let tokenArray = MLXArray([Int(nextToken)]).reshaped([1, 1])
            let (logits, newCacheK, newCacheV) = try model.forward(
                tokenArray,
                cacheK: cacheK,
                cacheV: cacheV
            )
            
            // Update cache
            cacheK = newCacheK ?? []
            cacheV = newCacheV ?? []
            
            // Extract logits for the last (and only) token
            let seqLen = logits.dim(1)
            nextLogits = logits[0..., (seqLen - 1)..., 0...].squeezed(axes: [1])
        }
        
        print("")
        print("")
        print("✅ [GemmaTest] Generation complete")
        print("   Total tokens generated: \(generatedTokens.count - inputTokens.count)")
        
        // 7. Decode full response
        print("")
        print("📄 [GemmaTest] Full response:")
        let fullResponse = try tokenizer.decode(generatedTokens)
        print(fullResponse)
    }
}
