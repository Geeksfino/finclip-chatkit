//
//  Phi3TransformerBlock.swift
//  GemmaTestAppFeature
//
//  Transformer block for Phi-3 with attention, MLP, and residual connections
//

import Foundation
import MLX
import MLXFast

/// Single transformer block for Phi-3
struct Phi3TransformerBlock {
    let inputNorm: Phi3RMSNorm
    let attention: Phi3Attention
    let postAttnNorm: Phi3RMSNorm
    let mlp: Phi3MLP
    let layerIdx: Int
    
    init?(
        layerIdx: Int,
        config: Phi3Config,
        actualHiddenDim: Int,
        weights: [String: MLXArray]
    ) {
        // Create input norm
        guard let norm1 = createRMSNorm(from: weights, layerIdx: layerIdx, config: config) else {
            print("⚠️  [Phi3TransformerBlock] Layer \(layerIdx) failed to create input norm")
            return nil
        }
        self.inputNorm = norm1
        
        // Create attention
        guard let attn = Phi3Attention(
            layerIdx: layerIdx,
            config: config,
            actualHiddenDim: actualHiddenDim,
            weights: weights
        ) else {
            print("⚠️  [Phi3TransformerBlock] Layer \(layerIdx) failed to create attention")
            return nil
        }
        self.attention = attn
        
        // Create post-attention norm
        guard let norm2 = createPostAttnRMSNorm(from: weights, layerIdx: layerIdx, config: config) else {
            print("⚠️  [Phi3TransformerBlock] Layer \(layerIdx) failed to create post-attn norm")
            return nil
        }
        self.postAttnNorm = norm2
        
        // Create MLP
        guard let mlpLayer = createPhi3MLP(
            layerIdx: layerIdx,
            actualHiddenDim: actualHiddenDim,
            weights: weights
        ) else {
            print("⚠️  [Phi3TransformerBlock] Layer \(layerIdx) failed to create MLP")
            return nil
        }
        self.mlp = mlpLayer
        
        self.layerIdx = layerIdx
    }
    
    /// Process through transformer block with residual connections and KV cache
    /// - Parameters:
    ///   - x: Input [batch, seq_len, hidden]
    ///   - cacheK: Optional cached K values [batch, heads, cached_seq, head_dim]
    ///   - cacheV: Optional cached V values [batch, heads, cached_seq, head_dim]
    /// - Returns: Tuple of (output, updated cacheK, updated cacheV)
    func callAsFunction(_ x: MLXArray, cacheK: MLXArray? = nil, cacheV: MLXArray? = nil) -> (MLXArray, MLXArray, MLXArray) {
        // Self-attention with residual
        let normed1 = inputNorm(x)
        let (attnOut, newCacheK, newCacheV) = attention(normed1, cacheK: cacheK, cacheV: cacheV)
        var hidden = x + attnOut
        
        // MLP with residual
        let normed2 = postAttnNorm(hidden)
        let mlpOut = mlp(normed2)
        hidden = hidden + mlpOut
        
        return (hidden, newCacheK, newCacheV)
    }
}

/// Create transformer block
func createPhi3TransformerBlock(
    layerIdx: Int,
    config: Phi3Config,
    actualHiddenDim: Int,
    weights: [String: MLXArray]
) -> Phi3TransformerBlock? {
    return Phi3TransformerBlock(
        layerIdx: layerIdx,
        config: config,
        actualHiddenDim: actualHiddenDim,
        weights: weights
    )
}

