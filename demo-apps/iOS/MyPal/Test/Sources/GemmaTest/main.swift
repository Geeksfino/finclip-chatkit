//
//  main.swift
//  GemmaTest
//
//  Command-line entry point for testing Gemma-3-270M model
//

import Foundation
import ArgumentParser
import MLX
import MLXRandom

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct GemmaTest: ParsableCommand {
    @Option(name: [.customShort("d"), .long], help: "Path to model directory")
    var modelPath: String
    
    @Option(name: .shortAndLong, help: "Input prompt")
    var prompt: String = "Hello"
    
    @Option(name: [.customShort("n"), .long], help: "Maximum number of tokens to generate")
    var maxTokens: Int = 50
    
    @Option(name: [.customShort("T"), .long], help: "Sampling temperature")
    var temperature: Float = 0.7
    
    @Option(name: [.customShort("k"), .long], help: "Top-k sampling parameter")
    var topK: Int = 50
    
    mutating func run() throws {
        print("🚀 [GemmaTest] Starting Gemma-3-270M test")
        print("   Model path: \(modelPath)")
        print("   Prompt: \(prompt)")
        print("   Max tokens: \(maxTokens)")
        print("   Temperature: \(temperature)")
        print("")
        
        // 1. Load model
        print("📦 [GemmaTest] Loading model...")
        let (config, weights) = try WeightLoader.loadFromDirectory(modelPath)
        print("✅ [GemmaTest] Model weights loaded")
        print("")
        
        // 2. Initialize model
        print("🏗️  [GemmaTest] Initializing model architecture...")
        let model = try Gemma3_270M(config: config, weights: weights)
        print("✅ [GemmaTest] Model initialized")
        print("")
        
        // 3. Load tokenizer
        print("📝 [GemmaTest] Loading tokenizer...")
        let tokenizer = try TokenizerLoader.load(from: modelPath, config: config)
        print("✅ [GemmaTest] Tokenizer loaded")
        print("")
        
        // 4. Encode prompt
        print("🔤 [GemmaTest] Encoding prompt...")
        let inputTokens = try tokenizer.encode(prompt)
        print("   Input tokens: \(inputTokens)")
        print("   Token count: \(inputTokens.count)")
        print("")
        
        // 5. Convert to MLXArray
        let tokensArray = MLXArray(inputTokens.map { Int32($0) })
        let batchTokens = tokensArray.reshaped([1, tokensArray.dim(0)])  // [1, seq]
        
        // 6. Generate tokens
        print("🤖 [GemmaTest] Generating response...")
        print("   (This may take a while)")
        print("")
        
        var generatedTokens = inputTokens
        var cacheK: [[MLXArray?]] = []
        var cacheV: [[MLXArray?]] = []
        
        for step in 0..<maxTokens {
            // Get last token for autoregressive generation
            let lastToken = generatedTokens.last!
            let lastTokenArray = MLXArray([Int32(lastToken)])
            let batchToken = lastTokenArray.reshaped([1, 1])  // [1, 1]
            
            // Generate next token logits
            let (logits, newCacheK, newCacheV) = try model.generateNextToken(
                batchToken,
                cacheK: &cacheK,
                cacheV: &cacheV
            )
            cacheK = newCacheK
            cacheV = newCacheV
            
            // Sample next token
            let nextToken: Int32
            if temperature == 0.0 {
                nextToken = greedySample(logits)
            } else {
                nextToken = topKSample(logits, topK: topK, temperature: temperature)
            }
            
            generatedTokens.append(nextToken)
            
            // Check for EOS
            if nextToken == tokenizer.eosTokenId {
                print("   [Step \(step)] EOS token generated, stopping")
                break
            }
            
            // Decode and print incrementally
            if step % 5 == 0 || step == maxTokens - 1 {
                let decoded = try tokenizer.decode([nextToken])
                print(decoded, terminator: "")
                fflush(stdout)
            }
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

// Entry point
if #available(macOS 10.15, *) {
    GemmaTest.main()
} else {
    fatalError("This program requires macOS 10.15 or later")
}
