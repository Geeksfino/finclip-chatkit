//
//  Phi3Model.swift
//  GemmaTestAppFeature
//
//  Full Phi-3 transformer implementation with RoPE, attention, MLP, RMSNorm
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
        print("   intermediateSize: \(intermediateSize)")
    }
}

/// Full Phi-3 transformer model
public class Phi3Model: LLMModel {
    public let modelType: ModelType = .phi3_mini
    let config: Phi3Config
    let embedWeight: MLXArray
    let embedding: Embedding  // Use MLXNN Embedding for efficient lookup
    let lmHeadWeight: MLXArray
    let finalNorm: Phi3RMSNorm?
    private let weights: [String: MLXArray]
    private var transformerBlocks: [Phi3TransformerBlock] = []
    private let actualHiddenDim: Int
    
    public init(config: Phi3Config, weights: [String: MLXArray]) throws {
        self.config = config
        self.weights = weights
        
        print("🏗️  [Phi3Model] Initializing Phi-3 transformer...")
        print("   Layers: \(config.numLayers)")
        print("   Hidden: \(config.hiddenSize), Heads: \(config.numAttentionHeads)")
        
        guard let embedW = weights["model.embed_tokens.weight"] else {
            throw ModelError.loadFailed("Missing embedding weight")
        }
        self.embedWeight = embedW
        self.embedding = Embedding(weight: embedW)  // Create MLXNN Embedding for efficient lookup
        
        guard let lmHeadW = weights["lm_head.weight"] else {
            throw ModelError.loadFailed("Missing lm_head weight")
        }
        self.lmHeadWeight = lmHeadW
        
        // Detect actual hidden dimension from embeddings
        // Note: Embeddings might not be quantized, so their dimension might differ
        // After dequantization of other weights, we should use config.hiddenSize
        let embedDim = embedW.shape[1]
        print("   Embedding dim: \(embedDim), Config hidden size: \(config.hiddenSize)")
        
        // For actualHiddenDim, use config.hiddenSize after dequantization
        // (dequantized weights will have config.hiddenSize dimensions)
        self.actualHiddenDim = config.hiddenSize
        
        // Create final norm
        self.finalNorm = createFinalRMSNorm(from: weights, config: config)
        
        // Load transformer blocks
        print("   Loading transformer blocks...")
        
        // Try to load transformer blocks - they should work if dequantization was successful
        // Check by verifying a key weight (like qkv_proj or q_proj) has correct dimensions
        let testLayerKey = "model.layers.0.self_attn.qkv_proj.weight"
        let testLayerKeyAlt = "model.layers.0.self_attn.q_proj.weight"
        
        var canLoadLayers = false
        if let testWeight = weights[testLayerKey] ?? weights[testLayerKeyAlt] {
            // Check if the weight's input dimension matches config.hiddenSize
            let weightInputDim = testWeight.shape[1]
            if weightInputDim == config.hiddenSize {
                canLoadLayers = true
                print("   ✅ Weight dimensions match config - loading transformer blocks...")
            } else {
                print("   ⚠️  Weight input dim (\(weightInputDim)) doesn't match config (\(config.hiddenSize))")
                print("   ⚠️  This may indicate incomplete dequantization")
            }
        } else {
            // If we can't find test weight, try loading anyway (might be different naming)
            canLoadLayers = true
            print("   ⚠️  Could not verify weight dimensions, attempting to load blocks...")
        }
        
        if canLoadLayers {
            // After dequantization, all weights should have config.hiddenSize dimensions
            // Use actualHiddenDim which is set to config.hiddenSize
            print("   Using hidden dim: \(actualHiddenDim) for transformer blocks")
            
            for layerIdx in 0..<config.numLayers {
                if let block = createPhi3TransformerBlock(
                    layerIdx: layerIdx,
                    config: config,
                    actualHiddenDim: actualHiddenDim,
                    weights: weights
                ) {
                    transformerBlocks.append(block)
                    if layerIdx < 3 || layerIdx >= config.numLayers - 1 {
                        print("   ✓ Layer \(layerIdx) loaded")
                    }
                } else {
                    print("   ⚠️  Failed to load layer \(layerIdx)")
                }
            }
        } else {
            print("   ⚠️  Transformer blocks disabled - dimension mismatch")
            print("   ⚠️  This may indicate the model needs different dequantization logic")
        }
        
        print("   Embeddings: \(embedW.shape)")
        print("   LM Head: \(lmHeadW.shape)")
        print("   Loaded \(transformerBlocks.count)/\(config.numLayers) transformer blocks")
        
        if transformerBlocks.count == config.numLayers {
            print("✅ [Phi3Model] Initialized (full transformer)")
        } else {
            print("✅ [Phi3Model] Initialized (embedding mode)")
        }
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
        
        // Step 1: Embed tokens
        var x = try getEmbeddings(inputTokens)
        
        // Step 2: Initialize cache arrays if needed
        // Cache structure: [[MLXArray?]] where cacheK[layerIdx][0] is the cache for that layer
        var layerCacheK: [[MLXArray?]] = []
        var layerCacheV: [[MLXArray?]] = []
        
        if let existingCacheK = cacheK, let existingCacheV = cacheV, 
           !existingCacheK.isEmpty, !existingCacheV.isEmpty {
            // Use existing cache
            layerCacheK = existingCacheK
            layerCacheV = existingCacheV
            // Ensure we have enough cache entries for all layers
            while layerCacheK.count < transformerBlocks.count {
                layerCacheK.append([nil])
            }
            while layerCacheV.count < transformerBlocks.count {
                layerCacheV.append([nil])
            }
        } else {
            // Initialize empty cache for all layers: each layer has one cache entry
            layerCacheK = Array(repeating: [nil], count: transformerBlocks.count)
            layerCacheV = Array(repeating: [nil], count: transformerBlocks.count)
        }
        
        // Step 3: Process through transformer blocks with KV cache
        print("🔄 [Phi3Model.forward] Processing \(transformerBlocks.count) layers...")
        
        for (idx, block) in transformerBlocks.enumerated() {
            // Extract cache for this layer (first element of the array)
            let layerK = layerCacheK[idx].first ?? nil
            let layerV = layerCacheV[idx].first ?? nil
            
            let (output, newK, newV) = block(x, cacheK: layerK, cacheV: layerV)
            x = output
            // Update cache for this layer
            layerCacheK[idx] = [newK]
            layerCacheV[idx] = [newV]
            
            if idx % max(1, transformerBlocks.count / 4) == 0 {
                print("   ✓ Layer \(idx + 1)/\(transformerBlocks.count) done")
            }
        }
        
        // Step 4: Apply final norm
        if let norm = finalNorm {
            x = norm(x)
        }
        
        // Step 5: Project to vocabulary
        let logits = try matmul(x, lmHeadWeight.asType(.float32).T)
        
        return (logits, layerCacheK, layerCacheV)
    }
    
    // MARK: - Helper Methods
    
    private func getEmbeddings(_ tokenIds: MLXArray) throws -> MLXArray {
        // Use MLXNN Embedding for efficient token ID to embedding lookup
        // This correctly extracts actual token IDs from the input array
        // tokenIds shape: [batch, seq] with actual token ID values
        return embedding(tokenIds)
    }
}

/// Phi-3 model loader
public class Phi3Loader: ModelLoader {
    public static func load(from directory: String) throws -> LLMModel {
        print("📦 [Phi3Loader] Loading Phi-3 model from: \(directory)")
        let (configDict, weightsRaw) = try WeightLoader.loadFromDirectory(directory)
        let config = Phi3Config(from: configDict)
        print("⏱️  [Phi3Loader] Loaded \(weightsRaw.count) tensors")
        
        // Check if model is quantized (has .scales and .biases tensors)
        let hasScales = weightsRaw.keys.contains(where: { $0.hasSuffix(".scales") })
        let hasBiases = weightsRaw.keys.contains(where: { $0.hasSuffix(".biases") })
        
        let weights: [String: MLXArray]
        if hasScales && hasBiases {
            print("🔧 [Phi3Loader] Quantized model detected - dequantizing...")
            // Pass target hidden dimension for proper expansion
            weights = QuantizationUtils.dequantizeWeights(weightsRaw, targetHiddenDim: config.hiddenSize)
        } else {
            print("✅ [Phi3Loader] Float model - using weights as-is")
            weights = weightsRaw
        }
        
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
