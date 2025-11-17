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
        
        // 4. Encode prompt
        print("🔤 [GemmaTest] Encoding prompt...")
        let inputTokens = try tokenizer.encode(config.prompt)
        print("   Input tokens: \(inputTokens)")
        print("   Token count: \(inputTokens.count)")
        print("")
        
        // 5. Prime the model with the prompt tokens to build KV cache
        print("🤖 [GemmaTest] Generating response...")
        print("   (This may take a while)")
        print("")
        
        var generatedTokens = inputTokens
        let eosTokenId = Int32(gemmaConfig.eosTokenId)
        var cacheK: [[MLXArray?]] = []
        var cacheV: [[MLXArray?]] = []
        var logitsForNext: MLXArray? = nil
        
        for token in inputTokens {
            let tokenArray = MLXArray([token]).reshaped([1, 1])
            let (logits, newCacheK, newCacheV) = try model.generateNextToken(
                tokenArray,
                cacheK: &cacheK,
                cacheV: &cacheV
            )
            cacheK = newCacheK
            cacheV = newCacheV
            logitsForNext = logits
        }
        
        guard var nextLogits = logitsForNext else {
            print("❌ [GemmaTest] Failed to prime model with prompt tokens")
            return
        }
        
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
            
            let tokenArray = MLXArray([nextToken]).reshaped([1, 1])
            let (logits, newCacheK, newCacheV) = try model.generateNextToken(
                tokenArray,
                cacheK: &cacheK,
                cacheV: &cacheV
            )
            cacheK = newCacheK
            cacheV = newCacheV
            nextLogits = logits
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
