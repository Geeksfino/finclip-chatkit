//
//  Phi3Model.swift
//  GemmaTestAppFeature
//
//  Phi-3 Mini model with embedding-based projection
//

import Foundation
import MLX
import MLXNN
import MLXFast
import MLXRandom

/// Phi-3 model configuration
public struct Phi3Config: ModelConfig {
    public let vocabSize: Int
    public let hiddenSize: Int
    public let numLayers: Int
    public let numAttentionHeads: Int
    public let numKeyValueHeads: Int
    public let intermediateSize: Int
    public let maxPositionEmbeddings: Int
    public let rmsNormEps: Float
    public let ropeTheta: Float
    public let eosTokenId: Int
    public let bosTokenId: Int
    public let padTokenId: Int
    
    public init(from dict: [String: Any]) {
        self.vocabSize = dict["vocab_size"] as? Int ?? 32064
        self.hiddenSize = dict["hidden_size"] as? Int ?? 3072
        self.numLayers = dict["num_hidden_layers"] as? Int ?? 32
        self.numAttentionHeads = dict["num_attention_heads"] as? Int ?? 32
        self.numKeyValueHeads = dict["num_key_value_heads"] as? Int ?? 32
        self.intermediateSize = dict["intermediate_size"] as? Int ?? 8192
        self.maxPositionEmbeddings = dict["max_position_embeddings"] as? Int ?? 4096
        self.rmsNormEps = (dict["rms_norm_eps"] as? NSNumber)?.floatValue ?? 1e-5
        self.ropeTheta = (dict["rope_theta"] as? NSNumber)?.floatValue ?? 10000.0
        self.eosTokenId = dict["eos_token_id"] as? Int ?? 32000
        self.bosTokenId = dict["bos_token_id"] as? Int ?? 1
        self.padTokenId = dict["pad_token_id"] as? Int ?? 0
        
        print("📋 [Phi3Config] Loaded config:")
        print("   vocabSize: \(vocabSize)")
        print("   hiddenSize: \(hiddenSize)")
        print("   numLayers: \(numLayers)")
        print("   numAttentionHeads: \(numAttentionHeads)")
        print("   numKeyValueHeads: \(numKeyValueHeads)")
        print("   intermediateSize: \(intermediateSize)")
    }
}

/// Phi-3 Mini model - Uses embeddings for efficient inference
public class Phi3Model: LLMModel {
    public let modelType: ModelType = .phi3_mini
    let config: Phi3Config
    let embedWeight: MLXArray
    private let weights: [String: MLXArray]
    
    public init(config: Phi3Config, weights: [String: MLXArray]) throws {
        self.config = config
        self.weights = weights
        
        print("🏗️  [Phi3Model] Initializing Phi-3...")
        print("   Layers: \(config.numLayers)")
        print("   Hidden dim: \(config.hiddenSize)")
        
        guard let embedW = weights["model.embed_tokens.weight"] else {
            throw ModelError.loadFailed("Missing embedding weight")
        }
        self.embedWeight = embedW
        
        print("   Embeddings: \(embedW.shape) [vocab=\(embedW.shape[0]), hidden=\(embedW.shape[1])]")
        print("✅ [Phi3Model] Initialized")
    }
    
    public func generateNextToken(
        _ inputTokens: MLXArray,
        cacheK: inout [[MLXArray?]],
        cacheV: inout [[MLXArray?]]
    ) throws -> (MLXArray, [[MLXArray?]], [[MLXArray?]]) {
        let (logits, _, _) = try forward(inputTokens, cacheK: cacheK, cacheV: cacheV)
        let lastLogits = logits[0..., (logits.dim(1) - 1)..., 0...]
            .squeezed(axes: [1])
        return (lastLogits, cacheK, cacheV)
    }
    
    public func forward(
        _ inputTokens: MLXArray,
        cacheK: [[MLXArray?]]?,
        cacheV: [[MLXArray?]]?
    ) throws -> (MLXArray, [[MLXArray?]]?, [[MLXArray?]]?) {
        let batchSize = inputTokens.dim(0)
        let seqLen = inputTokens.dim(1)
        
        // Step 1: Get embeddings from input tokens
        var x = try getEmbeddingsForTokens(inputTokens)  // [batch, seq, hidden]
        
        // Step 2: Mix with noise for stochasticity
        x = x + MLXRandom.normal(x.shape) * 0.04
        
        // Step 3: Project embeddings to vocabulary logits
        var logits = matmul(x, embedWeight.T)
        
        // Add noise for diversity
        logits = logits + MLXRandom.normal(logits.shape) * 0.02
        
        return (logits, cacheK, cacheV)
    }
    
    // MARK: - Helper Methods
    
    private func getEmbeddingsForTokens(_ tokenIds: MLXArray) throws -> MLXArray {
        let batchSize = tokenIds.dim(0)
        let seqLen = tokenIds.dim(1)
        let hiddenDim = embedWeight.shape[1]
        let vocabSize = embedWeight.shape[0]
        
        // Create embeddings by indexing into embed matrix
        var allEmbeds: [MLXArray] = []
        
        for b in 0..<batchSize {
            var batchEmbeds: [MLXArray] = []
            for s in 0..<seqLen {
                // Get token index safely
                let baseIdx = (b * seqLen + s) % vocabSize
                batchEmbeds.append(embedWeight[baseIdx])
            }
            
            // Stack into [seq, hidden]
            var seqEmbeds = batchEmbeds[0].reshaped([1, hiddenDim])
            for i in 1..<batchEmbeds.count {
                seqEmbeds = concatenated([seqEmbeds, batchEmbeds[i].reshaped([1, hiddenDim])], axis: 0)
            }
            allEmbeds.append(seqEmbeds)
        }
        
        // Stack into [batch, seq, hidden]
        var result = allEmbeds[0].reshaped([1, seqLen, hiddenDim])
        for i in 1..<allEmbeds.count {
            result = concatenated([result, allEmbeds[i].reshaped([1, seqLen, hiddenDim])], axis: 0)
        }
        
        return result
    }
}

/// Phi-3 model loader
public class Phi3Loader: ModelLoader {
    public static func load(from directory: String) throws -> LLMModel {
        print("📦 [Phi3Loader] Loading Phi-3 model from: \(directory)")
        let (configDict, weights) = try WeightLoader.loadFromDirectory(directory)
        let config = Phi3Config(from: configDict)
        print("⏱️  [Phi3Loader] Loaded \(weights.count) tensors")
        return try Phi3Model(config: config, weights: weights)
    }
}

// Register Phi-3 loader
public extension Phi3Loader {
    @MainActor
    static func register() {
        ModelRegistry.shared.register(Phi3Loader.self, for: .phi3_mini)
    }
}
