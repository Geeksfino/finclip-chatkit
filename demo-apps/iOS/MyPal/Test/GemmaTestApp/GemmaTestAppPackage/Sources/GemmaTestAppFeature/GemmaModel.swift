//
//  Gemma3Model.swift
//  GemmaTest
//
//  Swift MLX loader for Gemma-3-270M with low-dimensional embedding projection
//

import Foundation
import MLX
import MLXFast

// MARK: - Utility Helpers

fileprivate func dumpAvailableWeightNames(_ weights: [String: MLXArray], limit: Int = 150) {
    print("📦 Available weights (showing up to \(limit)):")
    var i = 0
    for k in weights.keys.sorted() {
        if let shape = weights[k]?.shape {
            print("   • \(k)   shape=\(shape)")
        }
        i += 1
        if i >= limit { break }
    }
}

fileprivate func findTensor(_ weights: [String: MLXArray], _ names: [String], description: String) throws -> MLXArray {
    for n in names {
        if let t = weights[n] { return t }
    }
    print("❌ [GemmaLoader] Missing \(description). Tried names: \(names.joined(separator: ", "))")
    dumpAvailableWeightNames(weights, limit: 150)
    throw NSError(domain: "GemmaLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing tensor: \(description)"])
}

// MARK: - Linear Wrapper

struct GemmaLinear {
    let weight: MLXArray    // [out, in]
    let bias: MLXArray?     // [out]
    
    init(weight: MLXArray, bias: MLXArray?) {
        self.weight = weight
        self.bias = bias
    }
    
    func callAsFunction(_ x: MLXArray) -> MLXArray {
        var out = x.matmul(weight.transposed())
        if let b = bias { out = out + b }
        return out
    }
}

// MARK: - LayerNorm Wrapper

struct GemmaLayerNorm {
    let weight: MLXArray?
    let bias: MLXArray?
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

struct GemmaRoPE {
    static func apply(q: MLXArray, k: MLXArray, base: Float = 10000.0) -> (MLXArray, MLXArray) {
        let headDim = q.shape.last ?? 0
        precondition(headDim % 2 == 0, "RoPE requires even head dimension")
        
        let half = headDim / 2
        let seqLen = q.shape[q.shape.count - 2]
        
        var freqVals: [Float] = []
        for i in 0..<half {
            freqVals.append(pow(base, -2.0 * Float(i) / Float(headDim)))
        }
        
        var angles: [Float] = []
        for p in 0..<seqLen {
            for f in freqVals {
                angles.append(Float(p) * f)
            }
        }
        
        let angleArr = MLXArray(angles).reshaped([seqLen, half])
        let cosArr = MLX.cos(angleArr).reshaped([1, 1, seqLen, half])
        let sinArr = MLX.sin(angleArr).reshaped([1, 1, seqLen, half])
        
        let qEven = q[0..<q.dim(0), 0..<q.dim(1), 0..<q.dim(2), 0..<half]
        let qOdd  = q[0..<q.dim(0), 0..<q.dim(1), 0..<q.dim(2), half..<headDim]
        let kEven = k[0..<k.dim(0), 0..<k.dim(1), 0..<k.dim(2), 0..<half]
        let kOdd  = k[0..<k.dim(0), 0..<k.dim(1), 0..<k.dim(2), half..<headDim]
        
        let qRotEven = qEven * cosArr - qOdd * sinArr
        let qRotOdd  = qEven * sinArr + qOdd * cosArr
        let kRotEven = kEven * cosArr - kOdd * sinArr
        let kRotOdd  = kEven * sinArr + kOdd * cosArr
        
        let qRot = concatenated([qRotEven, qRotOdd], axis: -1)
        let kRot = concatenated([kRotEven, kRotOdd], axis: -1)
        return (qRot, kRot)
    }
}

fileprivate func createAdditiveCausalMask(s: Int, seqTotal: Int) -> MLXArray {
    var maskValues: [Float] = Array(repeating: 0.0, count: s * seqTotal)
    for i in 0..<s {
        for j in 0..<seqTotal {
            if j > i { maskValues[i * seqTotal + j] = -1e9 }
        }
    }
    return MLXArray(maskValues).reshaped([1, 1, s, seqTotal])
}

// MARK: - Attention

final class GemmaAttention {
    let qProj: GemmaLinear
    let kProj: GemmaLinear
    let vProj: GemmaLinear
    let oProj: GemmaLinear
    let numQHeads: Int
    let numKVHeads: Int
    let headDim: Int
    let expectedOIn: Int
    
    init(layerIndex: Int, config: GemmaConfig, weights: [String: MLXArray]) throws {
        let qW = try findTensor(weights, [
            "model.layers.\(layerIndex).attention.query.weight",
            "model.layers.\(layerIndex).self_attn.q_proj.weight",
            "layers.\(layerIndex).attention.wq.weight"
        ], description: "q_proj weight for layer \(layerIndex)")
        let qB = weights["model.layers.\(layerIndex).attention.query.bias"] ??
                 weights["model.layers.\(layerIndex).self_attn.q_proj.bias"]
        
        let kW = try findTensor(weights, [
            "model.layers.\(layerIndex).attention.key.weight",
            "model.layers.\(layerIndex).self_attn.k_proj.weight",
            "layers.\(layerIndex).attention.wk.weight"
        ], description: "k_proj weight for layer \(layerIndex)")
        let kB = weights["model.layers.\(layerIndex).attention.key.bias"] ??
                 weights["model.layers.\(layerIndex).self_attn.k_proj.bias"]
        
        let vW = try findTensor(weights, [
            "model.layers.\(layerIndex).attention.value.weight",
            "model.layers.\(layerIndex).self_attn.v_proj.weight",
            "layers.\(layerIndex).attention.wv.weight"
        ], description: "v_proj weight for layer \(layerIndex)")
        let vB = weights["model.layers.\(layerIndex).attention.value.bias"] ??
                 weights["model.layers.\(layerIndex).self_attn.v_proj.bias"]
        
        let oW = try findTensor(weights, [
            "model.layers.\(layerIndex).attention.output.weight",
            "model.layers.\(layerIndex).self_attn.o_proj.weight",
            "layers.\(layerIndex).attention.wo.weight"
        ], description: "o_proj weight for layer \(layerIndex)")
        let oB = weights["model.layers.\(layerIndex).attention.output.bias"] ??
                 weights["model.layers.\(layerIndex).self_attn.o_proj.bias"]
        
        self.qProj = GemmaLinear(weight: qW, bias: qB)
        self.kProj = GemmaLinear(weight: kW, bias: kB)
        self.vProj = GemmaLinear(weight: vW, bias: vB)
        self.oProj = GemmaLinear(weight: oW, bias: oB)
        
        self.numQHeads = config.numAttentionHeads
        self.numKVHeads = max(1, config.numKVHeads)
        self.headDim = qW.shape[0] / max(1, numQHeads)
        self.expectedOIn = oW.shape[1]
        
        print("🔧 [GemmaAttention] L\(layerIndex) qHeads=\(numQHeads) kvHeads=\(numKVHeads) headDim=\(headDim) oIn=\(expectedOIn)")
    }
    
    func forward(_ hidden: MLXArray, cacheK: MLXArray?, cacheV: MLXArray?) throws -> (MLXArray, MLXArray, MLXArray) {
        let b = hidden.dim(0)
        let s = hidden.dim(1)
        
        var q = qProj(hidden)
        var k = kProj(hidden)
        var v = vProj(hidden)
        
        q = q.reshaped([b, s, numQHeads, headDim]).transposed(0, 2, 1, 3)
        k = k.reshaped([b, s, numKVHeads, headDim]).transposed(0, 2, 1, 3)
        v = v.reshaped([b, s, numKVHeads, headDim]).transposed(0, 2, 1, 3)
        
        if numKVHeads < numQHeads {
            let factor = numQHeads / numKVHeads
            var kParts: [MLXArray] = []
            var vParts: [MLXArray] = []
            for _ in 0..<factor {
                kParts.append(k)
                vParts.append(v)
            }
            k = concatenated(kParts, axis: 1)
            v = concatenated(vParts, axis: 1)
        }
        
        let (qRot, kRot) = GemmaRoPE.apply(q: q, k: k)
        
        let newK: MLXArray
        if let cache = cacheK {
            newK = concatenated([cache, kRot], axis: 2)
        } else {
            newK = kRot
        }
        
        let newV: MLXArray
        if let cache = cacheV {
            newV = concatenated([cache, v], axis: 2)
        } else {
            newV = v
        }
        
        let kTrans = newK.transposed(0, 1, 3, 2)
        let scale = 1.0 / sqrt(Float(headDim))
        var scores = (qRot * scale).matmul(kTrans)
        let mask = createAdditiveCausalMask(s: s, seqTotal: newK.dim(2))
        scores = scores + mask
        
        let attn = softmax(scores, axis: -1)
        var attnOut = attn.matmul(newV)
        attnOut = attnOut.transposed(0, 2, 1, 3).reshaped([b, s, numQHeads * headDim])
        
        let last = attnOut.shape.last ?? 0
        if last != expectedOIn {
            if last > expectedOIn {
                attnOut = attnOut[0..<b, 0..<s, 0..<expectedOIn]
                print("⚠️ [GemmaAttention] Sliced attnOut \(last) -> \(expectedOIn)")
            } else {
                throw NSError(domain: "GemmaAttention", code: -1, userInfo: [NSLocalizedDescriptionKey: "attnOut smaller than oProj expects (\(last) < \(expectedOIn))"])
            }
        }
        
        let out = oProj(attnOut)
        return (out, newK, newV)
    }
}

// MARK: - Gemma MLP (SwiGLU)

final class GemmaMLP {
    let gate: GemmaLinear
    let up: GemmaLinear
    let down: GemmaLinear
    let expectedDownInput: Int
    
    init(layerIndex: Int, config: GemmaConfig, weights: [String: MLXArray]) throws {
        let gateW = try findTensor(weights, [
            "model.layers.\(layerIndex).mlp.gate.weight",
            "model.layers.\(layerIndex).mlp.gate_proj.weight",
            "layers.\(layerIndex).feed_forward.w1.weight"
        ], description: "mlp gate weight")
        let gateB = weights["model.layers.\(layerIndex).mlp.gate.bias"] ??
                    weights["model.layers.\(layerIndex).mlp.gate_proj.bias"] ??
                    weights["layers.\(layerIndex).feed_forward.w1.bias"]
        
        let upW = try findTensor(weights, [
            "model.layers.\(layerIndex).mlp.up.weight",
            "model.layers.\(layerIndex).mlp.up_proj.weight",
            "layers.\(layerIndex).feed_forward.w3.weight"
        ], description: "mlp up weight")
        let upB = weights["model.layers.\(layerIndex).mlp.up.bias"] ??
                  weights["model.layers.\(layerIndex).mlp.up_proj.bias"] ??
                  weights["layers.\(layerIndex).feed_forward.w3.bias"]
        
        let downW = try findTensor(weights, [
            "model.layers.\(layerIndex).mlp.down.weight",
            "model.layers.\(layerIndex).mlp.down_proj.weight",
            "layers.\(layerIndex).feed_forward.w2.weight"
        ], description: "mlp down weight")
        let downB = weights["model.layers.\(layerIndex).mlp.down.bias"] ??
                    weights["model.layers.\(layerIndex).mlp.down_proj.bias"] ??
                    weights["layers.\(layerIndex).feed_forward.w2.bias"]
        
        self.gate = GemmaLinear(weight: gateW, bias: gateB)
        self.up = GemmaLinear(weight: upW, bias: upB)
        self.down = GemmaLinear(weight: downW, bias: downB)
        self.expectedDownInput = downW.shape[1]
    }
    
    func callAsFunction(_ x: MLXArray) -> MLXArray {
        let g = gate(x)
        let u = up(x)
        var activated = g * silu(u)
        let last = activated.shape.last ?? 0
        if last != expectedDownInput {
            if last > expectedDownInput {
                let b = activated.dim(0)
                let s = activated.dim(1)
                activated = activated[0..<b, 0..<s, 0..<expectedDownInput]
            } else {
                fatalError("[GemmaMLP] activated smaller than expectedDownInput (\(last) < \(expectedDownInput))")
            }
        }
        return down(activated)
    }
}

// MARK: - Transformer Block

final class GemmaBlock {
    let attnNorm: GemmaLayerNorm
    let attn: GemmaAttention
    let mlpNorm: GemmaLayerNorm
    let mlp: GemmaMLP
    
    init(layerIndex: Int, config: GemmaConfig, weights: [String: MLXArray]) throws {
        let attnW = try findTensor(weights, [
            "model.layers.\(layerIndex).input_layernorm.weight",
            "layers.\(layerIndex).attention_norm.weight"
        ], description: "attention layernorm weight")
        let attnB = weights["model.layers.\(layerIndex).input_layernorm.bias"] ??
                    weights["layers.\(layerIndex).attention_norm.bias"]
        self.attnNorm = GemmaLayerNorm(weight: attnW, bias: attnB, eps: config.layerNormEps)
        
        self.attn = try GemmaAttention(layerIndex: layerIndex, config: config, weights: weights)
        
        let mlpW = try findTensor(weights, [
            "model.layers.\(layerIndex).post_attention_layernorm.weight",
            "layers.\(layerIndex).ffn_norm.weight"
        ], description: "mlp layernorm weight")
        let mlpB = weights["model.layers.\(layerIndex).post_attention_layernorm.bias"] ??
                   weights["layers.\(layerIndex).ffn_norm.bias"]
        self.mlpNorm = GemmaLayerNorm(weight: mlpW, bias: mlpB, eps: config.layerNormEps)
        
        self.mlp = try GemmaMLP(layerIndex: layerIndex, config: config, weights: weights)
    }
    
    func forward(_ hidden: MLXArray, cacheK: MLXArray?, cacheV: MLXArray?) throws -> (MLXArray, MLXArray, MLXArray) {
        let (attnOut, newK, newV) = try attn.forward(attnNorm(hidden), cacheK: cacheK, cacheV: cacheV)
        var h = hidden + attnOut
        let mlpOut = mlp.forward(mlpNorm(h))
        h = h + mlpOut
        return (h, newK, newV)
    }
}

// MARK: - Gemma3 Model

final class Gemma3Model: LLMModel {
    let modelType: ModelType = .gemma3_270m
    let config: GemmaConfig
    let embeddingTable: MLXArray
    let embedDim: Int
    let embedToHidden: GemmaLinear?
    let blocks: [GemmaBlock]
    let finalNorm: GemmaLayerNorm
    let lmHead: GemmaLinear
    
    init(config: GemmaConfig, weights: [String: MLXArray]) throws {
        self.config = config
        
        let embedNames = [
            "model.embed_tokens.weight",
            "embed_tokens.weight",
            "tok_embeddings.weight",
            "model.tokens_embed.weight"
        ]
        guard let embedding = embedNames.compactMap({ weights[$0] }).first else {
            dumpAvailableWeightNames(weights)
            throw NSError(domain: "Gemma3Model", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing embedding weight (tried \(embedNames.joined(separator: ", ")))"])
        }
        self.embeddingTable = embedding
        self.embedDim = embedding.shape.last ?? 0
        print("📦 [Gemma3Model] Embedding shape: \(embedding.shape) embedDim=\(embedDim) hiddenSize=\(config.hiddenSize)")
        
        if embedDim != config.hiddenSize {
            let projNames = [
                "model.embed_proj.weight",
                "model.embed_to_hidden.weight",
                "tok_embeddings_proj.weight",
                "model.tok_embeddings_proj.weight",
                "embed_projection.weight",
                "model.embed_tokens_projection.weight"
            ]
            if let projW = projNames.compactMap({ weights[$0] }).first {
                let projB = projNames.compactMap { weights[$0.replacingOccurrences(of: "weight", with: "bias")] }.first
                print("✅ [Gemma3Model] Found embedding projection \(projW.shape)")
                self.embedToHidden = GemmaLinear(weight: projW, bias: projB)
            } else {
                print("❌ [Gemma3Model] embedDim \(embedDim) != hidden \(config.hiddenSize) and no projection found.")
                dumpAvailableWeightNames(weights)
                throw NSError(domain: "Gemma3Model", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing embedding projection tensor for mapping \(embedDim)->\(config.hiddenSize)"])
            }
        } else {
            self.embedToHidden = nil
        }
        
        var tmpBlocks: [GemmaBlock] = []
        for i in 0..<config.numLayers {
            tmpBlocks.append(try GemmaBlock(layerIndex: i, config: config, weights: weights))
        }
        self.blocks = tmpBlocks
        
        let normW = weights["model.norm.weight"] ?? weights["norm.weight"]
        let normB = weights["model.norm.bias"] ?? weights["norm.bias"]
        self.finalNorm = GemmaLayerNorm(weight: normW, bias: normB, eps: config.layerNormEps)
        
        if let lmHeadW = weights["lm_head.weight"] ?? weights["model.lm_head.weight"] {
            let lmHeadB = weights["lm_head.bias"] ?? weights["model.lm_head.bias"]
            self.lmHead = GemmaLinear(weight: lmHeadW, bias: lmHeadB)
            print("✅ [Gemma3Model] Using explicit lm_head weight")
        } else {
            guard embedDim == config.hiddenSize else {
                dumpAvailableWeightNames(weights)
                throw NSError(domain: "Gemma3Model", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing lm_head.weight and cannot tie because embedDim != hiddenSize"])
            }
            self.lmHead = GemmaLinear(weight: embeddingTable, bias: nil)
            print("✅ [Gemma3Model] Using embedding table as lm_head (weight tying)")
        }
    }
    
    // MARK: - LLMModel
    
    func generateNextToken(
        _ inputTokens: MLXArray,
        cacheK: inout [[MLXArray?]],
        cacheV: inout [[MLXArray?]]
    ) throws -> (MLXArray, [[MLXArray?]], [[MLXArray?]]) {
        let flatK = flattenCaches(cacheK, layerCount: blocks.count)
        let flatV = flattenCaches(cacheV, layerCount: blocks.count)
        let (logits, newK, newV) = try run(tokens: inputTokens, cacheK: flatK, cacheV: flatV, useCache: true)
        cacheK = inflateCaches(newK)
        cacheV = inflateCaches(newV)
        
        let seqLen = logits.dim(1)
        let lastLogits = logits[0, seqLen - 1]
        return (lastLogits, cacheK, cacheV)
    }
    
    func forward(
        _ inputTokens: MLXArray,
        cacheK: [[MLXArray?]]?,
        cacheV: [[MLXArray?]]?
    ) throws -> (MLXArray, [[MLXArray?]]?, [[MLXArray?]]?) {
        let flatK = flattenCaches(cacheK, layerCount: blocks.count)
        let flatV = flattenCaches(cacheV, layerCount: blocks.count)
        let (logits, newK, newV) = try run(tokens: inputTokens, cacheK: flatK, cacheV: flatV, useCache: true)
        return (logits, inflateCaches(newK), inflateCaches(newV))
    }
    
    // MARK: - Core Execution
    
    private func embedTokens(_ tokens: MLXArray) -> MLXArray {
        return embeddingTable[tokens]
    }
    
    private func run(
        tokens: MLXArray,
        cacheK: [MLXArray?]?,
        cacheV: [MLXArray?]?,
        useCache: Bool
    ) throws -> (MLXArray, [MLXArray?], [MLXArray?]) {
        var hidden = embedTokens(tokens)
        if let proj = embedToHidden {
            hidden = proj(hidden)
        } else if embedDim != config.hiddenSize {
            fatalError("[Gemma3Model] embedDim != hiddenSize but no projection available")
        }
        
        var nextK = cacheK ?? Array(repeating: nil, count: blocks.count)
        var nextV = cacheV ?? Array(repeating: nil, count: blocks.count)
        
        for i in 0..<blocks.count {
            let (out, layerK, layerV) = try blocks[i].forward(hidden, cacheK: nextK[i], cacheV: nextV[i])
            hidden = out
            nextK[i] = useCache ? layerK : nil
            nextV[i] = useCache ? layerV : nil
        }
        
        hidden = finalNorm(hidden)
        let logits = lmHead(hidden)
        return (logits, nextK, nextV)
    }
}

// MARK: - Cache helpers

fileprivate func flattenCaches(_ caches: [[MLXArray?]]?, layerCount: Int) -> [MLXArray?] {
    guard let caches = caches, !caches.isEmpty else {
        return Array(repeating: nil, count: layerCount)
    }
    var flat: [MLXArray?] = Array(repeating: nil, count: layerCount)
    for i in 0..<min(layerCount, caches.count) {
        flat[i] = caches[i].last ?? nil
    }
    return flat
}

fileprivate func inflateCaches(_ caches: [MLXArray?]) -> [[MLXArray?]] {
    return caches.map { cache in
        if let cache = cache {
            return [cache]
        } else {
            return []
        }
    }
}

// MARK: - Loader

public class GemmaLoader: ModelLoader {
    public static func load(from directory: String) throws -> LLMModel {
        print("📦 [GemmaLoader] Loading Gemma model from: \(directory)")
        let (configDict, weights) = try WeightLoader.loadFromDirectory(directory)
        let config = GemmaConfig(from: configDict)
        print("⏱️  [GemmaLoader] Loaded \(weights.count) tensors")
        return try Gemma3Model(config: config, weights: weights)
    }
}

public extension GemmaLoader {
    @MainActor
    static func register() {
        ModelRegistry.shared.register(GemmaLoader.self, for: .gemma3_270m)
    }
}
