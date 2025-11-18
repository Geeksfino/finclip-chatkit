//
//  Phi3Attention.swift
//  GemmaTestAppFeature
//
//  Multi-head self-attention with RoPE for Phi-3
//

import Foundation
import MLX
import MLXFast

    /// Multi-head attention for Phi-3
struct Phi3Attention {
    let qkvProj: MLXArray?   // Combined QKV: [3*hidden, hidden] (for float16)
    let qProj: MLXArray?     // Separate Q: [hidden, hidden] (for quantized)
    let kProj: MLXArray?     // Separate K: [hidden, hidden]
    let vProj: MLXArray?     // Separate V: [hidden, hidden]
    let oProj: MLXArray      // [hidden, hidden]
    let rope: Phi3RoPE
    let config: Phi3Config
    let actualHiddenDim: Int
    let useCombinedQKV: Bool
    let layerIdx: Int  // For debugging
    
    init?(
        layerIdx: Int,
        config: Phi3Config,
        actualHiddenDim: Int,
        weights: [String: MLXArray]
    ) {
        let oKey = "model.layers.\(layerIdx).self_attn.o_proj.weight"
        guard let oW = weights[oKey] else {
            print("⚠️  [Phi3Attention] Layer \(layerIdx) missing o_proj weight")
            return nil
        }
        self.oProj = oW.asType(.float32)
        
        // Check for combined QKV projection first (Phi-3 float16 format)
        let qkvKey = "model.layers.\(layerIdx).self_attn.qkv_proj.weight"
        
        if let qkvW = weights[qkvKey] {
            // Combined QKV projection - keep as single tensor
            self.qkvProj = qkvW.asType(.float32)
            self.qProj = nil
            self.kProj = nil
            self.vProj = nil
            self.useCombinedQKV = true
            
            if layerIdx < 2 {
                print("   ✓ Layer \(layerIdx): Using combined qkv_proj (shape: \(qkvW.shape))")
            }
        } else {
            // Try separate Q, K, V projections (quantized format)
            let qKey = "model.layers.\(layerIdx).self_attn.q_proj.weight"
            let kKey = "model.layers.\(layerIdx).self_attn.k_proj.weight"
            let vKey = "model.layers.\(layerIdx).self_attn.v_proj.weight"
            
            guard let qW = weights[qKey],
                  let kW = weights[kKey],
                  let vW = weights[vKey] else {
                print("⚠️  [Phi3Attention] Layer \(layerIdx) missing attention weights")
                return nil
            }
            
            self.qkvProj = nil
            self.qProj = qW.asType(.float32)
            self.kProj = kW.asType(.float32)
            self.vProj = vW.asType(.float32)
            self.useCombinedQKV = false
            
            if layerIdx < 2 {
                print("   ✓ Layer \(layerIdx): Using separate q/k/v_proj")
            }
        }
        
        self.config = config
        self.actualHiddenDim = actualHiddenDim
        self.layerIdx = layerIdx
        
        let headDim = actualHiddenDim / config.numAttentionHeads
        self.rope = Phi3RoPE(ropeTheta: config.ropeTheta, headDim: headDim)
    }
    
    /// Apply multi-head attention with optional KV cache
    /// - Parameters:
    ///   - x: Input [batch, seq_len, hidden]
    ///   - cacheK: Optional cached K values [batch, heads, cached_seq, head_dim]
    ///   - cacheV: Optional cached V values [batch, heads, cached_seq, head_dim]
    /// - Returns: Tuple of (attention output, updated cacheK, updated cacheV)
    func callAsFunction(_ x: MLXArray, cacheK: MLXArray? = nil, cacheV: MLXArray? = nil) -> (MLXArray, MLXArray, MLXArray) {
        let batchSize = x.dim(0)
        let seqLen = x.dim(1)
        let xFloat = x.asType(.float32)
        
        // Project Q, K, V
        let q: MLXArray
        let k: MLXArray
        let v: MLXArray
        
        if useCombinedQKV, let qkvW = qkvProj {
            // Combined QKV: project first, then split output
            // qkvW shape: [3*hidden, hidden] = [9216, 3072]
            // Project: [batch, seq, hidden] @ [hidden, 3*hidden] = [batch, seq, 3*hidden]
            guard let qkv = try? matmul(xFloat, qkvW.T) else {
                print("⚠️  [Phi3Attention] QKV projection failed")
                let headDim = actualHiddenDim / config.numAttentionHeads
                let emptyCache = MLXArray.zeros([batchSize, config.numAttentionHeads, 0, headDim])
                return (x, emptyCache, emptyCache)
            }
            
            // Split output: [batch, seq, 3*hidden] -> Q, K, V each [batch, seq, hidden]
            let hiddenSize = actualHiddenDim
            q = qkv[0..., 0..., 0..<hiddenSize]
            k = qkv[0..., 0..., hiddenSize..<(2*hiddenSize)]
            v = qkv[0..., 0..., (2*hiddenSize)..<(3*hiddenSize)]
        } else if let qW = qProj, let kW = kProj, let vW = vProj {
            // Separate Q, K, V projections
            guard let qProj = try? matmul(xFloat, qW.T),
                  let kProj = try? matmul(xFloat, kW.T),
                  let vProj = try? matmul(xFloat, vW.T) else {
                print("⚠️  [Phi3Attention] Projection failed")
                let headDim = actualHiddenDim / config.numAttentionHeads
                let emptyCache = MLXArray.zeros([batchSize, config.numAttentionHeads, 0, headDim])
                return (x, emptyCache, emptyCache)
            }
            q = qProj
            k = kProj
            v = vProj
        } else {
            print("⚠️  [Phi3Attention] No QKV weights available")
            // Return identity with empty cache
            let emptyCache = MLXArray.zeros([batchSize, config.numAttentionHeads, 0, actualHiddenDim / config.numAttentionHeads])
            return (x, emptyCache, emptyCache)
        }
        
        // Reshape for multi-head attention
        // Q, K, V shape: [batch, seq_len, hidden] where hidden = num_heads * head_dim
        // Need: [batch, heads, seq_len, head_dim]
        let headDim = actualHiddenDim / config.numAttentionHeads
        
        // Standard approach: reshape to [batch, seq, heads, head_dim] then transpose
        // This ensures correct interleaving of heads
        let qReshaped = reshape(q, [batchSize, seqLen, config.numAttentionHeads, headDim])
        let kReshaped = reshape(k, [batchSize, seqLen, config.numAttentionHeads, headDim])
        let vReshaped = reshape(v, [batchSize, seqLen, config.numAttentionHeads, headDim])
        
        // Transpose to [batch, heads, seq_len, head_dim]
        var kHeads = kReshaped.transposed(0, 2, 1, 3)  // [batch, heads, seq, head_dim]
        var vHeads = vReshaped.transposed(0, 2, 1, 3)  // [batch, heads, seq, head_dim]
        let qHeads = qReshaped.transposed(0, 2, 1, 3)  // [batch, heads, seq, head_dim]
        
        // Concatenate with cache if available (cache stores K/V WITHOUT RoPE)
        var kHeadsFull: MLXArray
        var vHeadsFull: MLXArray
        
        if let cachedK = cacheK, let cachedV = cacheV {
            // Concatenate: cached (no RoPE) + new (no RoPE)
            kHeadsFull = concatenated([cachedK, kHeads], axis: 2)
            vHeadsFull = concatenated([cachedV, vHeads], axis: 2)
        } else {
            // No cache: use new tokens only
            kHeadsFull = kHeads
            vHeadsFull = vHeads
        }
        
        let totalSeqLen = kHeadsFull.shape[2]  // cached + new sequence length
        let cachedLen = cacheK?.shape[2] ?? 0
        
        // Apply RoPE to full sequence (cached + new) with correct positions
        // Q: only new tokens, starting at position cachedLen
        // K: all tokens (cached + new), starting at position 0
        let (qRope, _) = applySimplifiedRoPE(qHeads, qHeads, headDim: headDim, startPos: cachedLen)
        let (_, kRope) = applySimplifiedRoPE(kHeadsFull, kHeadsFull, headDim: headDim, startPos: 0)
        
        // Update cache: store K and V WITHOUT RoPE (we'll apply RoPE next time)
        let newCacheK = kHeadsFull  // Store without RoPE
        let newCacheV = vHeadsFull  // Store without RoPE
        
        // Compute attention scores: Q (new tokens) @ K (all tokens)
        // qRope: [batch, heads, new_seq_len, head_dim]
        // kRope: [batch, heads, total_seq_len, head_dim]
        // scores: [batch, heads, new_seq_len, total_seq_len]
        let scores = computeAttentionScores(qRope, kRope, headDim: headDim)
        
        // Log attention scores for debugging (first layer only)
        if layerIdx == 0 {
            print("   [Layer 0 Attention] Scores shape: \(scores.shape), newSeqLen=\(seqLen), totalSeqLen=\(totalSeqLen)")
        }
        
        // Apply causal mask (only mask future positions relative to each query position)
        let maskedScores = applyCausalMask(scores, newSeqLen: seqLen, totalSeqLen: totalSeqLen)
        
        // Softmax
        let attnWeights = softmax(maskedScores, axis: -1)
        
        // Log attention weights after softmax (first layer only)
        if layerIdx == 0 {
            if seqLen <= 10 {
                let firstHeadWeights = attnWeights[0, 0, 0..., 0...]
                print("   [Layer 0 Attention] Weights after softmax (diagonal):")
                for i in 0..<min(3, seqLen) {
                    let weight = firstHeadWeights[i, i].item(Float.self)
                    print("      [\(i),\(i)] = \(String(format: "%.3f", weight))")
                }
            } else {
                let firstHeadWeights = attnWeights[0, 0, 0..., 0...]
                let firstWeight = firstHeadWeights[0, 0].item(Float.self)
                let lastWeight = firstHeadWeights[seqLen-1, seqLen-1].item(Float.self)
                // Check if last token attends to earlier tokens (should be > 0)
                let lastToFirst = firstHeadWeights[seqLen-1, 0].item(Float.self)
                print("   [Layer 0 Attention] Weights: [0,0]=\(String(format: "%.3f", firstWeight)), [\(seqLen-1),\(seqLen-1)]=\(String(format: "%.3f", lastWeight)), [\(seqLen-1),0]=\(String(format: "%.3f", lastToFirst))")
            }
        }
        
        // Apply to V (full sequence)
        // attnWeights: [batch, heads, new_seq_len, total_seq_len]
        // vHeadsFull: [batch, heads, total_seq_len, head_dim]
        // attnOutput: [batch, heads, new_seq_len, head_dim]
        let attnOutput = try? matmul(attnWeights, vHeadsFull)
        guard let attnOutput = attnOutput else {
            print("⚠️  [Phi3Attention] Attention application failed")
            return (x, newCacheK, newCacheV)
        }
        
        // Reshape back: [batch, heads, new_seq_len, head_dim] -> [batch, new_seq_len, heads, head_dim] -> [batch, new_seq_len, hidden]
        let attnTransposed = attnOutput.transposed(0, 2, 1, 3)  // [batch, new_seq, heads, head_dim]
        let output = reshape(attnTransposed, [batchSize, seqLen, actualHiddenDim])
        
        // Output projection
        let finalOutput = try? matmul(output, oProj.T)
        
        return (finalOutput ?? x, newCacheK, newCacheV)
    }
    
    private func computeAttentionScores(_ q: MLXArray, _ k: MLXArray, headDim: Int) -> MLXArray {
        // Q: [batch, heads, seq_len, head_dim]
        // K: [batch, heads, seq_len, head_dim]
        // Need: [batch, heads, seq_len, seq_len]
        
        let scale = 1.0 / sqrt(Float(headDim))
        
        // Transpose K: [batch, heads, seq_len, head_dim] -> [batch, heads, head_dim, seq_len]
        let kT = k.transposed(0, 1, 3, 2)  // Swap last two dimensions
        
        // matmul: [batch, heads, seq_len, head_dim] @ [batch, heads, head_dim, seq_len]
        //       -> [batch, heads, seq_len, seq_len]
        let scores = try? matmul(q, kT) * scale
        return scores ?? q
    }
    
    private func applyCausalMask(_ scores: MLXArray, newSeqLen: Int, totalSeqLen: Int) -> MLXArray {
        // Create causal mask for new tokens attending to all tokens (cached + new)
        // For each new token at position i (relative to start), it can attend to:
        // - All cached tokens (positions 0..<cachedLen)
        // - New tokens at positions <= i (positions cachedLen..<cachedLen+i+1)
        // Cannot attend to future new tokens
        
        let cachedLen = totalSeqLen - newSeqLen
        
        var maskValues: [Float] = []
        for i in 0..<newSeqLen {
            for j in 0..<totalSeqLen {
                if j < cachedLen {
                    // Can attend to all cached tokens
                    maskValues.append(0.0)
                } else {
                    // For new tokens: can attend if j - cachedLen <= i
                    let newTokenPos = j - cachedLen
                    maskValues.append(newTokenPos <= i ? 0.0 : -Float.infinity)
                }
            }
        }
        
        let mask = MLXArray(maskValues).reshaped([1, 1, newSeqLen, totalSeqLen])
        
        // Apply mask by adding to scores
        let maskedScores = scores + mask
        
        return maskedScores
    }
    
    private func reshape(_ tensor: MLXArray, _ shape: [Int]) -> MLXArray {
        return tensor.reshaped(shape)
    }
    
    /// Apply RoPE (Rotary Position Embeddings) to Q and K - CORRECTED VERSION
    /// q, k shape: [batch, heads, seq_len, head_dim]
    /// startPos: Starting position for RoPE (for KV cache, this is the cached sequence length)
    private func applySimplifiedRoPE(_ q: MLXArray, _ k: MLXArray, headDim: Int, startPos: Int = 0) -> (MLXArray, MLXArray) {
        let batchSize = q.shape[0]
        let numHeads = q.shape[1]
        let seqLen = q.shape[2]
        
        // Compute inverse frequencies: theta_i = rope_theta^(-2i/d) for i in [0, d/2)
        var invFreqs: [Float] = []
        for i in 0..<(headDim / 2) {
            let exponent = -2.0 * Float(i) / Float(headDim)
            let freq = pow(config.ropeTheta, exponent)
            invFreqs.append(freq)
        }
        let invFreqArray = MLXArray(invFreqs)  // [head_dim/2]
        
        // Create position indices: [startPos, startPos+1, ..., startPos+seqLen-1]
        let positions = MLXArray((startPos..<(startPos + seqLen)).map { Float($0) })  // [seq_len]
        
        // Compute angles: outer product of positions and frequencies
        // angles[pos, i] = pos * inv_freq[i]
        // Shape: [seq_len, head_dim/2]
        let positionsExpanded = positions.reshaped([seqLen, 1])  // [seq_len, 1]
        let invFreqExpanded = invFreqArray.reshaped([1, headDim / 2])  // [1, head_dim/2]
        let angles = positionsExpanded * invFreqExpanded  // [seq_len, head_dim/2]
        
        // Compute cos and sin
        let cosValues = MLX.cos(angles)  // [seq_len, head_dim/2]
        let sinValues = MLX.sin(angles)  // [seq_len, head_dim/2]
        
        // Reshape for broadcasting: [1, 1, seq_len, head_dim/2]
        let cosBcast = cosValues.reshaped([1, 1, seqLen, headDim / 2])
        let sinBcast = sinValues.reshaped([1, 1, seqLen, headDim / 2])
        
        // Apply rotation to Q and K
        let qRotated = applyRotation(q, cos: cosBcast, sin: sinBcast, headDim: headDim)
        let kRotated = applyRotation(k, cos: cosBcast, sin: sinBcast, headDim: headDim)
        
        return (qRotated, kRotated)
    }
    
    /// Apply rotation using cos and sin
    /// x shape: [batch, heads, seq_len, head_dim]
    /// cos, sin shape: [1, 1, seq_len, head_dim/2]
    private func applyRotation(_ x: MLXArray, cos: MLXArray, sin: MLXArray, headDim: Int) -> MLXArray {
        let halfDim = headDim / 2
        
        // Split x into two halves along last dimension
        let x1 = x[0..., 0..., 0..., 0..<halfDim]      // [batch, heads, seq_len, head_dim/2]
        let x2 = x[0..., 0..., 0..., halfDim..<headDim]  // [batch, heads, seq_len, head_dim/2]
        
        // RoPE rotation formula (standard LLaMA/Phi-3):
        // x_rot = [x1 * cos - x2 * sin, x1 * sin + x2 * cos]
        let rotated1 = x1 * cos - x2 * sin
        let rotated2 = x1 * sin + x2 * cos
        
        // Concatenate back: [batch, heads, seq_len, head_dim]
        let rotated = concatenated([rotated1, rotated2], axis: -1)
        
        return rotated
    }
}

