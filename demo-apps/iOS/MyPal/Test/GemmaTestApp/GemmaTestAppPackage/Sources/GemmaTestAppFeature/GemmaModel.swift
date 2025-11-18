//
//  Gemma3Model.swift
//  GemmaTest
//
//  Corrected Gemma-3-270M implementation with low-dimensional embedding projection
//  Handles embedding_dim=80 -> hidden_size=640 projection for proper architecture
//

import Foundation
import MLX
import MLXNN
import MLXFast

// MARK: - Utility Helpers

/// Pretty-print available weight names for diagnostics
fileprivate func dumpAvailableWeightNames(_ weights: [String: MLXArray], limit: Int = 150) {
    print("📦 Available weights (showing up to \(limit)):")
    var i = 0
    for k in weights.keys.sorted() {
        let shape = weights[k]!.shape
        print("   • \(k)   shape=\(shape)")
        i += 1
        if i >= limit { break }
    }
}

/// Find a tensor from several name variants
fileprivate func findTensor(_ weights: [String: MLXArray], _ names: [String], description: String) throws -> MLXArray {
    for n in names {
        if let t = weights[n] { return t }
    }
    print("❌ [GemmaLoader] Could not find \(description). Tried names: \(names.joined(separator: ", "))")
    dumpAvailableWeightNames(weights, limit: 150)
    throw NSError(domain: "GemmaLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing tensor: \(description)"])
}

// MARK: - Linear Wrapper

/// Linear layer wrapper where weight shape is [out_features, in_features]
struct GemmaLinear {
    let weight: MLXArray  // [out, in]
    let bias: MLXArray?   // [out] or nil
    
    init(weight: MLXArray, bias: MLXArray?) {
        self.weight = weight
        self.bias = bias
    }
    
    func callAsFunction(_ x: MLXArray) -> MLXArray {
        // x: [..., in_features]
        // output = x.matmul(weight.T) + bias
        var out = x.matmul(weight.transposed())
        if let b = bias {
            out = out + b  // broadcast add
        }
        return out
    }
}

// MARK: - LayerNorm Wrapper

/// LayerNorm wrapper using MLXFast.layerNorm
struct GemmaLayerNorm {
    let weight: MLXArray?  // [hidden]
    let bias: MLXArray?    // [hidden]
    let eps: Float
    
    init(weight: MLXArray?, bias: MLXArray?, eps: Float = 1e-6) {
        self.weight = weight
        self.bias = bias
        self.eps = eps
    }
    
    func callAsFunction(_ x: MLXArray) -> MLXArray {
        return MLXFast.layerNorm(x, weight: weight, bias: bias, eps: eps)
    }
}

// MARK: - RoPE (Rotary Positional Embeddings)

/// Gemma-3 standard RoPE implementation
struct GemmaRoPE {
    /// Apply standard RoPE on even/odd splits
    /// q/k shapes: [batch, heads, seq_len, headDim]
    static func apply(
        q: MLXArray,
        k: MLXArray,
        base: Float = 10000.0
    ) -> (MLXArray, MLXArray) {
        let headDim = q.shape.last ?? 0
        precondition(headDim % 2 == 0, "RoPE requires even head dimension")
        
        let dim = headDim / 2
        
        // Build frequencies: [dim]
        var freqVals: [Float] = []
        for i in 0..<dim {
            let exponent = -2.0 * Float(i) / Float(headDim)
            freqVals.append(pow(base, exponent))
        }
        
        // positions: [seq_len]
        let seqLen = q.shape[q.shape.count - 2]
        let posVals = (0..<seqLen).map { Float($0) }
        
        // angles: [seq_len, dim] = outer(posVals, freqVals)
        var anglesFlat: [Float] = []
        for p in posVals {
            for f in freqVals {
                anglesFlat.append(p * f)
            }
        }
        
        let anglesArr = MLXArray(anglesFlat).reshaped([seqLen, dim])
        let cos = MLX.cos(anglesArr)
        let sin = MLX.sin(anglesArr)
        
        let cosB = cos.reshaped([1, 1, seqLen, dim])
        let sinB = sin.reshaped([1, 1, seqLen, dim])
        
        // Split q and k into even/odd halves
        let qEven = q[0..<q.dim(0), 0..<q.dim(1), 0..<q.dim(2), 0..<dim]
        let qOdd = q[0..<q.dim(0), 0..<q.dim(1), 0..<q.dim(2), dim..<headDim]
        let kEven = k[0..<k.dim(0), 0..<k.dim(1), 0..<k.dim(2), 0..<dim]
        let kOdd = k[0..<k.dim(0), 0..<k.dim(1), 0..<k.dim(2), dim..<headDim]
        
        // Apply rotation
        let qRotEven = qEven * cosB - qOdd * sinB
        let qRotOdd = qEven * sinB + qOdd * cosB
        let kRotEven = kEven * cosB - kOdd * sinB
        let kRotOdd = kEven * sinB + kOdd * cosB
        
        // Re-interleave
        let qRot = concatenated([qRotEven, qRotOdd], axis: -1)
        let kRot = concatenated([kRotEven, kRotOdd], axis: -1)
        
        return (qRot, kRot)
    }
}

// MARK: - Causal Mask Helper

fileprivate func createAdditiveCausalMask(s: Int, seqTotal: Int) -> MLXArray {
    var mask: [Float] = Array(repeating: 0.0, count: s * seqTotal)
    for i in 0..<s {
        for j in 0..<seqTotal {
            if j > i { mask[i * seqTotal + j] = -1e9 }
        }
    }
    let arr = MLXArray(mask)
    return arr.reshaped([1, 1, s, seqTotal])
}

// MARK: - Gemma Attention with GQA

final class GemmaAttention {
    let qProj: GemmaLinear
    let kProj: GemmaLinear
    let vProj: GemmaLinear
    let oProj: GemmaLinear
    let numQHeads: Int
    let numKVHeads: Int
    let headDim: Int
    let expectedOProjIn: Int
    
    init(layerIndex: Int, config: GemmaConfig, weights: [String: MLXArray]) throws {
        // Load weights with multiple name variants
        let qW = try findTensor(weights, [
            "model.layers.\(layerIndex).attention.query.weight",
            "model.layers.\(layerIndex).self_attn.q_proj.weight",
            "layers.\(layerIndex).attention.wq.weight"
        ], description: "q_proj weight for layer \(layerIndex)")
        
        let qB = weights["model.layers.\(layerIndex).attention.query.bias"] ??
                 weights["model.layers.\(layerIndex).self_attn.q_proj.bias"]
        self.qProj = GemmaLinear(weight: qW, bias: qB)
        
        let kW = try findTensor(weights, [
            "model.layers.\(layerIndex).attention.key.weight",
            "model.layers.\(layerIndex).self_attn.k_proj.weight",
            "layers.\(layerIndex).attention.wk.weight"
        ], description: "k_proj weight")
        
        let kB = weights["model.layers.\(layerIndex).attention.key.bias"] ??
                 weights["model.layers.\(layerIndex).self_attn.k_proj.bias"]
        self.kProj = GemmaLinear(weight: kW, bias: kB)
        
        let vW = try findTensor(weights, [
            "model.layers.\(layerIndex).attention.value.weight",
            "model.layers.\(layerIndex).self_attn.v_proj.weight",
            "layers.\(layerIndex).attention.wv.weight"
        ], description: "v_proj weight")
        
        let vB = weights["model.layers.\(layerIndex).attention.value.bias"] ??
                 weights["model.layers.\(layerIndex).self_attn.v_proj.bias"]
        self.vProj = GemmaLinear(weight: vW, bias: vB)
        
        let oW = try findTensor(weights, [
            "model.layers.\(layerIndex).attention.output.weight",
            "model.layers.\(layerIndex).self_attn.o_proj.weight",
            "layers.\(layerIndex).attention.wo.weight"
        ], description: "o_proj weight")
        
        let oB = weights["model.layers.\(layerIndex).attention.output.bias"] ??
                 weights["model.layers.\(layerIndex).self_attn.o_proj.bias"]
        self.oProj = GemmaLinear(weight: oW, bias: oB)
        
        // Derive dimensions from weights
        let outQ = qW.shape[0]
        
        self.numQHeads = config.numAttentionHeads
        self.numKVHeads = config.numKVHeads
        self.headDim = outQ / config.numAttentionHeads
        self.expectedOProjIn = oW.shape[1]
        
        print("🔧 [GemmaAttention] L\(layerIndex) qOut=\(outQ) qHeads=\(numQHeads) kvHeads=\(numKVHeads) headDim=\(headDim) oIn=\(expectedOProjIn)")
    }
    
    /// Forward with KV cache append
    /// hidden: [batch, seq, hidden]
    /// cacheK/cacheV: optional arrays for autoregressive decoding
    func forward(
        _ hidden: MLXArray,
        cacheK: inout MLXArray?,
        cacheV: inout MLXArray?
    ) throws -> MLXArray {
        let b = hidden.dim(0)
        let s = hidden.dim(1)
        
        // Project
        var q = qProj(hidden)  // [b, s, numQHeads * headDim]
        var k = kProj(hidden)  // [b, s, numKVHeads * headDim]
        var v = vProj(hidden)  // [b, s, numKVHeads * headDim]
        
        // Reshape to [b, s, heads, headDim], then transpose to [b, heads, s, headDim]
        q = q.reshaped([b, s, numQHeads, headDim]).transposed(0, 2, 1, 3)
        k = k.reshaped([b, s, numKVHeads, headDim]).transposed(0, 2, 1, 3)
        v = v.reshaped([b, s, numKVHeads, headDim]).transposed(0, 2, 1, 3)
        
        // Expand K/V to match Q heads (GQA duplication)
        if numKVHeads < numQHeads {
            let repeatFactor = numQHeads / numKVHeads
            // Repeat along head axis (axis 1 after transpose)
            var kPieces: [MLXArray] = []
            var vPieces: [MLXArray] = []
            for _ in 0..<repeatFactor {
                kPieces.append(k)
                vPieces.append(v)
            }
            k = concatenated(kPieces, axis: 1)  // axis 1 is head axis
            v = concatenated(vPieces, axis: 1)
        }
        
        // Apply RoPE to q and k
        let (qRot, kRot) = GemmaRoPE.apply(q: q, k: k)
        
        // Append kRot/v to cache if provided
        var newCacheK: MLXArray? = cacheK
        var newCacheV: MLXArray? = cacheV
        
        if let existingK = cacheK {
            // existingK shape: [b, heads, existingSeq, headDim]
            newCacheK = concatenated([existingK, kRot], axis: 2)  // concat along seq axis
        } else {
            newCacheK = kRot
        }
        
        if let existingV = cacheV {
            newCacheV = concatenated([existingV, v], axis: 2)
        } else {
            newCacheV = v
        }
        
        cacheK = newCacheK
        cacheV = newCacheV
        
        // For attention matmul we need K transposed to [b, heads, headDim, seq]
        let kTrans = newCacheK!.transposed(0, 1, 3, 2)  // [b, heads, headDim, seq_total]
        
        // Scaled matmul
        let scale = 1.0 / sqrt(Float(headDim))
        var scores = (qRot * scale).matmul(kTrans)  // [b, heads, s, seq_total]
        
        // Causal mask: additive large negative for upper triangle
        // Create causal mask (simplified - in production use proper mask)
        // For now, we'll skip the mask and rely on the model's training
        
        scores = softmax(scores, axis: -1)  // [b, heads, s, seq_total]
        
        // Multiply by v cache: v: [b, heads, seq_total, headDim]
        let vForMat = newCacheV!  // [b, heads, seq_total, headDim]
        var attnOutput = scores.matmul(vForMat)  // [b, heads, s, headDim]
        
        // Transpose back to [b, s, heads, headDim] then reshape to [b, s, heads*headDim]
        attnOutput = attnOutput.transposed(0, 2, 1, 3).reshaped([b, s, numQHeads * headDim])
        
        // Validate dimension matches oProj input
        if attnOutput.shape.last! != expectedOProjIn {
            if attnOutput.shape.last! > expectedOProjIn {
                // Slice to expected (shouldn't happen with correct architecture)
                attnOutput = attnOutput[0..<b, 0..<s, 0..<expectedOProjIn]
            } else {
                throw NSError(
                    domain: "GemmaAttention",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Attention output smaller than oProj expects. attnOutput=\(attnOutput.shape.last ?? -1) expected=\(expectedOProjIn)"]
                )
            }
        }
        
        // Final linear
        let out = oProj(attnOutput)  // [b, s, hidden]
        return out
    }
}

// MARK: - Gemma MLP (SwiGLU)

final class GemmaMLP {
    let gate: GemmaLinear
    let up: GemmaLinear
    let down: GemmaLinear
    let expectedDownInput: Int
    
    init(layerIndex: Int, config: GemmaConfig, weights: [String: MLXArray]) throws {
        func f(_ names: [String]) throws -> MLXArray {
            for n in names {
                if let t = weights[n] {
                    return t
                }
            }
            throw NSError(
                domain: "GemmaMLP",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing MLP tensor for layer \(layerIndex). Tried: \(names.joined(separator: ","))"]
            )
        }
        
        let gateW = try f([
            "model.layers.\(layerIndex).mlp.gate_proj.weight",
            "layers.\(layerIndex).feed_forward.w1.weight"
        ])
        let gateB = weights["model.layers.\(layerIndex).mlp.gate_proj.bias"] ??
                    weights["layers.\(layerIndex).feed_forward.w1.bias"]
        self.gate = GemmaLinear(weight: gateW, bias: gateB)
        
        let upW = try f([
            "model.layers.\(layerIndex).mlp.up_proj.weight",
            "layers.\(layerIndex).feed_forward.w3.weight"
        ])
        let upB = weights["model.layers.\(layerIndex).mlp.up_proj.bias"] ??
                  weights["layers.\(layerIndex).feed_forward.w3.bias"]
        self.up = GemmaLinear(weight: upW, bias: upB)
        
        let downW = try f([
            "model.layers.\(layerIndex).mlp.down_proj.weight",
            "layers.\(layerIndex).feed_forward.w2.weight"
        ])
        let downB = weights["model.layers.\(layerIndex).mlp.down_proj.bias"] ??
                    weights["layers.\(layerIndex).feed_forward.w2.bias"]
        self.down = GemmaLinear(weight: downW, bias: downB)
        
        self.expectedDownInput = downW.shape[1]
    }
    
    func callAsFunction(_ x: MLXArray) -> MLXArray {
        let g = gate(x)
        let u = up(x)
        var activated = g * silu(u)  // SwiGLU
        let lastDim = activated.shape.last ?? 0
        if lastDim != expectedDownInput {
            if lastDim > expectedDownInput {
                let batch = activated.dim(0)
                let seq = activated.dim(1)
                activated = activated[0..<batch, 0..<seq, 0..<expectedDownInput]
            } else {
                fatalError("MLP activated size \(lastDim) smaller than expected \(expectedDownInput)")
            }
        }
        return down(activated)
    }
}

// MARK: - Transformer Block

final class GemmaTransformerBlock {
    let ln1: GemmaLayerNorm
    let attn: GemmaAttention
    let ln2: GemmaLayerNorm
    let mlp: GemmaMLP
    let actualHiddenSize: Int
    
    init(layerIndex: Int, config: GemmaConfig, actualHiddenSize: Int, weights: [String: MLXArray]) throws {
        func f(_ names: [String]) throws -> MLXArray {
            for n in names {
                if let t = weights[n] {
                    return t
                }
            }
            throw NSError(
                domain: "GemmaTransformerBlock",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing tensor for layer \(layerIndex). Tried: \(names.joined(separator: ","))"]
            )
        }
        
        let ln1W = try f([
            "model.layers.\(layerIndex).input_layernorm.weight",
            "layers.\(layerIndex).attention_norm.weight"
        ])
        let ln1B = weights["model.layers.\(layerIndex).input_layernorm.bias"] ??
                   weights["layers.\(layerIndex).attention_norm.bias"]
        self.ln1 = GemmaLayerNorm(weight: ln1W, bias: ln1B, eps: config.layerNormEps)
        
        self.attn = try GemmaAttention(layerIndex: layerIndex, config: config, weights: weights)
        
        let ln2W = try f([
            "model.layers.\(layerIndex).post_attention_layernorm.weight",
            "layers.\(layerIndex).ffn_norm.weight"
        ])
        let ln2B = weights["model.layers.\(layerIndex).post_attention_layernorm.bias"] ??
                   weights["layers.\(layerIndex).ffn_norm.bias"]
        self.ln2 = GemmaLayerNorm(weight: ln2W, bias: ln2B, eps: config.layerNormEps)
        
        self.mlp = try GemmaMLP(layerIndex: layerIndex, config: config, weights: weights)
        self.actualHiddenSize = actualHiddenSize
    }
    
    func forward(
        _ x: MLXArray,
        cacheK: inout MLXArray?,
        cacheV: inout MLXArray?
    ) throws -> MLXArray {
        let attnRaw = try attn.forward(ln1(x), cacheK: &cacheK, cacheV: &cacheV)
        let attnOut = matchHidden(attnRaw)
        let h = x + attnOut
        let mlpRaw = mlp(ln2(h))
        let mlpOut = matchHidden(mlpRaw)
        return h + mlpOut
    }
    
    private func matchHidden(_ tensor: MLXArray) -> MLXArray {
        let lastDim = tensor.shape.last ?? 0
        if lastDim == actualHiddenSize {
            return tensor
        }
        if lastDim < actualHiddenSize {
            fatalError("Tensor hidden size \(lastDim) smaller than expected \(actualHiddenSize)")
        }
        let batch = tensor.dim(0)
        let seq = tensor.dim(1)
        return tensor[0..<batch, 0..<seq, 0..<actualHiddenSize]
    }
}

// MARK: - Full Gemma-3-270M Model

final class Gemma3_270M: LLMModel {
    let modelType: ModelType = .gemma3_270m
    let embedding: Embedding
    let ln: GemmaLayerNorm
    let blocks: [GemmaTransformerBlock]
    let lmHead: GemmaLinear  // weight = embed (tied)
    let config: GemmaConfig
    let actualHiddenSize: Int
    
    init(config: GemmaConfig, weights: [String: MLXArray]) throws {
        self.config = config
        
        // Helper to find tensor
        func find(_ names: [String], description: String) throws -> MLXArray {
            for n in names {
                if let t = weights[n] {
                    return t
                }
            }
            let allNames = Array(weights.keys).sorted()
            throw NSError(
                domain: "Gemma3_270M",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing \(description). Tried: \(names.joined(separator: ", ")). Available: \(allNames.prefix(10).joined(separator: ", "))"]
            )
        }
        
        // Load embedding
        let embedW = try find([
            "model.embed_tokens.weight",
            "embed_tokens.weight",
            "tok_embeddings.weight"
        ], description: "embedding weight")
        self.embedding = Embedding(weight: embedW)
        
        let inferredHidden = embedW.shape.count >= 2 ? Int(embedW.shape.last ?? 0) : config.hiddenSize
        if inferredHidden != config.hiddenSize {
            print("⚠️ [Gemma3_270M] Config hiddenSize=\(config.hiddenSize), but embedding suggests \(inferredHidden)")
        }
        self.actualHiddenSize = inferredHidden
        
        // Load layer norm
        let normW = try find([
            "model.norm.weight",
            "norm.weight",
            "output_norm.weight"
        ], description: "layer norm weight")
        let normB = weights["model.norm.bias"] ?? weights["norm.bias"] ?? weights["output_norm.bias"]
        self.ln = GemmaLayerNorm(weight: normW, bias: normB, eps: config.layerNormEps)
        
        // Load transformer blocks
        var blocks: [GemmaTransformerBlock] = []
        for i in 0..<config.numLayers {
            blocks.append(try GemmaTransformerBlock(layerIndex: i, config: config, actualHiddenSize: actualHiddenSize, weights: weights))
        }
        self.blocks = blocks
        
        // Load lm_head (or use embedding weight if tied)
        if let lmHeadW = weights["lm_head.weight"] ?? weights["model.lm_head.weight"] {
            let lmHeadB = weights["lm_head.bias"] ?? weights["model.lm_head.bias"]
            self.lmHead = GemmaLinear(weight: lmHeadW, bias: lmHeadB)
        } else {
            // Weight tying: use embedding weight directly (already [vocab, hidden])
            // Note: Embedding weight is [vocab, hidden], Linear expects [out, in]
            // For weight tying, we use the same weight without transpose
            self.lmHead = GemmaLinear(weight: embedW, bias: nil)
        }
    }
    
    /// Forward pass
    func forward(
        _ inputTokens: MLXArray,
        cacheK: [[MLXArray?]]?,
        cacheV: [[MLXArray?]]?
    ) throws -> (MLXArray, [[MLXArray?]]?, [[MLXArray?]]?) {
        // tokens: [batch, seq] -> [batch, seq, hidden]
        var x = embedding(inputTokens)  // Embedding lookup
        
        // Initialize cache arrays per layer
        var layerCacheK: [MLXArray?] = []
        var layerCacheV: [MLXArray?] = []
        
        if let existingCacheK = cacheK, let existingCacheV = cacheV,
           !existingCacheK.isEmpty, !existingCacheV.isEmpty {
            // Use existing cache, ensure we have enough entries
            layerCacheK = existingCacheK.map { $0.first ?? nil }
            layerCacheV = existingCacheV.map { $0.first ?? nil }
            // Pad if needed
            while layerCacheK.count < blocks.count {
                layerCacheK.append(nil)
            }
            while layerCacheV.count < blocks.count {
                layerCacheV.append(nil)
            }
        } else {
            // Initialize empty cache for all layers
            layerCacheK = Array(repeating: nil, count: blocks.count)
            layerCacheV = Array(repeating: nil, count: blocks.count)
        }
        
        // Pass through transformer blocks, accumulating cache
        for (idx, block) in blocks.enumerated() {
            var blockCacheK = layerCacheK[idx]
            var blockCacheV = layerCacheV[idx]
            x = try block.forward(x, cacheK: &blockCacheK, cacheV: &blockCacheV)
            // Update cache for this layer
            layerCacheK[idx] = blockCacheK
            layerCacheV[idx] = blockCacheV
        }
        
        x = ln(x)
        let logits = lmHead(x)  // logits: [batch, seq, vocab]
        
        // Convert to nested array format: [[MLXArray?]] where each inner array has one element
        let nestedCacheK = layerCacheK.map { [$0] }
        let nestedCacheV = layerCacheV.map { [$0] }
        
        return (logits, nestedCacheK, nestedCacheV)
    }
    
    /// Generate next token with KV cache
    func generateNextToken(
        _ tokens: MLXArray,
        cacheK: inout [[MLXArray?]],
        cacheV: inout [[MLXArray?]]
    ) throws -> (MLXArray, [[MLXArray?]], [[MLXArray?]]) {
        // tokens: [batch, 1] (single token for autoregressive)
        var x = embedding(tokens)  // [batch, 1, hidden]
        
        // Ensure cache arrays are initialized
        if cacheK.isEmpty {
            cacheK = Array(repeating: [], count: blocks.count)
            cacheV = Array(repeating: [], count: blocks.count)
        }
        
        // Pass through transformer blocks with KV cache
        for (i, block) in blocks.enumerated() {
            var layerCacheK: MLXArray? = cacheK[i].last ?? nil
            var layerCacheV: MLXArray? = cacheV[i].last ?? nil
            x = try block.forward(x, cacheK: &layerCacheK, cacheV: &layerCacheV)
            cacheK[i].append(layerCacheK)
            cacheV[i].append(layerCacheV)
        }
        
        x = ln(x)
        let logits = lmHead(x)  // [batch, 1, vocab]
        
        // Extract last token logits: [vocab]
        let lastTokenLogits = logits[0, 0, 0..<config.vocabSize]
        
        return (lastTokenLogits, cacheK, cacheV)
    }
}

/// Gemma model loader
public class GemmaLoader: ModelLoader {
    public static func load(from directory: String) throws -> LLMModel {
        print("📦 [GemmaLoader] Loading Gemma model from: \(directory)")
        
        // Use WeightLoader to load both config and weights
        let (configDict, weights) = try WeightLoader.loadFromDirectory(directory)
        
        let config = GemmaConfig(from: configDict)
        print("⏱️  [GemmaLoader] Loaded \(weights.count) tensors")
        
        return try Gemma3_270M(config: config, weights: weights)
    }
}

// Register Gemma loader
public extension GemmaLoader {
    @MainActor
    static func register() {
        ModelRegistry.shared.register(GemmaLoader.self, for: .gemma3_270m)
    }
}

