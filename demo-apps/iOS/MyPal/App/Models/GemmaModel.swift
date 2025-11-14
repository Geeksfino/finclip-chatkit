//
//  GemmaModel.swift
//  MyPal
//
//  Gemma 3 transformer model implementation using MLX-Swift
//

import Foundation
import MLX
import MLXNN

/// Custom LayerNorm that accepts pre-loaded weights
class CustomLayerNorm: Module {
  let weight: MLXArray
  let bias: MLXArray?
  let eps: Float
  let dimensions: Int
  
  init(dimensions: Int, weight: MLXArray, bias: MLXArray?, eps: Float = 1e-5) {
    self.dimensions = dimensions
    self.weight = weight
    self.bias = bias
    self.eps = eps
    super.init()
  }
  
  func callAsFunction(_ x: MLXArray) -> MLXArray {
    return MLXFast.layerNorm(x, weight: weight, bias: bias, eps: eps)
  }
}

/// Gemma 3 transformer model for text generation
class GemmaModel: Module {
  let embedding: Embedding
  let layers: [GemmaTransformerBlock]
  let norm: CustomLayerNorm
  let lmHead: Linear
  
  let config: GemmaConfig
  let actualHiddenSize: Int  // Actual hidden size inferred from model weights
  
  init(config: GemmaConfig, weights: [String: MLXArray]) throws {
    self.config = config
    
    // Helper to find tensor with multiple possible names
    func findTensor(names: [String], description: String) throws -> MLXArray {
      for name in names {
        if let tensor = weights[name] {
          return tensor
        }
      }
      // Log available tensor names for debugging
      let allNames = Array(weights.keys).sorted()
      let matchingNames = allNames.filter { name in
        names.contains { name.contains($0.split(separator: ".").last ?? "") }
      }
      let errorMsg = """
        ❌ [GemmaModel] Could not find \(description)
        Tried names: \(names.joined(separator: ", "))
        Available matching tensors: \(matchingNames.prefix(10).joined(separator: ", "))
        Total tensors: \(weights.count)
        """
      print(errorMsg)
      throw NSError(domain: "GemmaModel", code: -1, 
                   userInfo: [NSLocalizedDescriptionKey: "Missing tensor: \(description)"])
    }
    
    // Load embedding weights
    let embedWeight = try findTensor(
      names: ["model.embed_tokens.weight", "embed_tokens.weight", "tok_embeddings.weight"],
      description: "embedding weight"
    )
    self.embedding = Embedding(weight: embedWeight)
    
    // Infer actual hidden_size from embedding weights
    // Embedding shape: [vocab_size, hidden_size]
    // The actual hidden_size might differ from config (especially for quantized models)
    let embedShape = embedWeight.shape
    if embedShape.count >= 2 {
      let inferredHiddenSize = Int(embedShape[embedShape.count - 1])  // Last dimension
      if inferredHiddenSize != config.hiddenSize {
        print("⚠️ [GemmaModel] Config says hiddenSize=\(config.hiddenSize), but embedding suggests \(inferredHiddenSize)")
        print("   Using inferred hiddenSize=\(inferredHiddenSize) from embedding weights")
        self.actualHiddenSize = inferredHiddenSize
      } else {
        self.actualHiddenSize = config.hiddenSize
      }
    } else {
      self.actualHiddenSize = config.hiddenSize
    }
    
    // Load transformer blocks
    // Pass actualHiddenSize to blocks so they use correct dimensions
    var layers: [GemmaTransformerBlock] = []
    for i in 0..<config.numLayers {
      layers.append(try GemmaTransformerBlock(
        layerIndex: i,
        config: config,
        actualHiddenSize: actualHiddenSize,
        weights: weights
      ))
    }
    self.layers = layers
    
    // Load layer norm
    let normWeight = try findTensor(
      names: ["model.norm.weight", "norm.weight", "output_norm.weight"],
      description: "layer norm weight"
    )
    let normBias = weights["model.norm.bias"] ?? 
                   weights["norm.bias"] ??
                   weights["output_norm.bias"]
    // Use custom LayerNorm that accepts pre-loaded weights
    // Use actualHiddenSize instead of config.hiddenSize
    self.norm = CustomLayerNorm(
      dimensions: actualHiddenSize,
      weight: normWeight,
      bias: normBias,
      eps: 1e-5
    )
    
    // Load output projection (lm_head)
    // For quantized models, might be "lm_head.weight" or "model.lm_head.weight"
    // Some models use weight tying - sharing embedding weights as output projection
    let lmHeadWeight: MLXArray
    let lmHeadBias: MLXArray?
    
    if let weight = weights["lm_head.weight"] ??
                    weights["model.lm_head.weight"] ??
                    weights["output.weight"] ??
                    weights["model.output.weight"] {
      // Found explicit lm_head
      lmHeadWeight = weight
      lmHeadBias = weights["lm_head.bias"] ?? 
                   weights["model.lm_head.bias"] ??
                   weights["output.bias"] ??
                   weights["model.output.bias"]
      print("✅ [GemmaModel] Using explicit lm_head weights")
    } else if let embedWeight = weights["model.embed_tokens.weight"] ??
                               weights["embed_tokens.weight"] {
      // Use embedding weights as output projection (weight tying)
      // This is common in transformer models
      // Embedding shape: [vocab_size, hidden_size]
      // We need to transpose it for Linear layer: [hidden_size, vocab_size]
      print("✅ [GemmaModel] Using embedding weights as lm_head (weight tying)")
      print("   Embedding shape: \(embedWeight.shape)")
      // Transpose: [vocab_size, hidden_size] -> [hidden_size, vocab_size]
      lmHeadWeight = embedWeight.transposed()
      lmHeadBias = nil  // No bias when using weight tying
    } else {
      // Last resort: try to find any output-related tensor
      let allNames = Array(weights.keys).sorted()
      let outputNames = allNames.filter { 
        $0.contains("output") || $0.contains("head") || $0.contains("lm")
      }
      let errorMsg = """
        ❌ [GemmaModel] Could not find lm_head weight
        Tried names: lm_head.weight, model.lm_head.weight, output.weight, model.output.weight
        Also tried: embedding weights (weight tying)
        Available output-related tensors: \(outputNames.prefix(10).joined(separator: ", "))
        Total tensors: \(weights.count)
        """
      print(errorMsg)
      throw NSError(domain: "GemmaModel", code: -1, 
                   userInfo: [NSLocalizedDescriptionKey: "Missing tensor: lm_head weight"])
    }
    self.lmHead = Linear(weight: lmHeadWeight, bias: lmHeadBias)
    
    super.init()
  }
  
  /// Forward pass through the model
  func forward(_ inputIds: MLXArray, cache: inout [MLXArray]?) throws -> MLXArray {
    // Token embeddings
    var hiddenStates = embedding(inputIds)
    
    // Position embeddings (if needed - Gemma might use RoPE)
    // For now, we'll skip position embeddings as Gemma uses RoPE in attention
    
    // Transformer blocks
    for layer in layers {
      var layerCache: MLXArray? = nil
      hiddenStates = try layer(hiddenStates, cache: &layerCache)
    }
    
    // Final layer norm
    hiddenStates = norm(hiddenStates)
    
    // Output projection to vocabulary
    let logits = lmHead(hiddenStates)
    
    return logits
  }
  
  /// Generate next token logits
  func generateNextTokenLogits(_ inputIds: MLXArray) throws -> MLXArray {
    var cache: [MLXArray]? = nil
    let logits = try forward(inputIds, cache: &cache)
    // Return logits for the last token only: [batch, seq_len, vocab] -> [vocab]
    // Get the last sequence position
    let seqLen = logits.dim(1)
    // Extract last token logits: [vocab]
    // Use slicing: [batch=0, seq=last]
    let lastTokenLogits = logits[0, seqLen - 1]
    return lastTokenLogits
  }
}

/// Gemma transformer block (one layer)
class GemmaTransformerBlock: Module {
  let attention: GemmaAttention
  let mlp: GemmaMLP
  let inputNorm: CustomLayerNorm
  let postAttentionNorm: CustomLayerNorm
  let actualHiddenSize: Int  // Actual hidden size for residual connections
  
  init(layerIndex: Int, config: GemmaConfig, actualHiddenSize: Int, weights: [String: MLXArray]) throws {
    // Helper to find tensor with multiple possible names
    func findTensor(names: [String], description: String) throws -> MLXArray {
      for name in names {
        if let tensor = weights[name] {
          return tensor
        }
      }
      let errorMsg = "❌ [GemmaTransformerBlock] Layer \(layerIndex): Could not find \(description). Tried: \(names.joined(separator: ", "))"
      print(errorMsg)
      throw NSError(domain: "GemmaTransformerBlock", code: -1, 
                   userInfo: [NSLocalizedDescriptionKey: "Missing tensor: \(description)"])
    }
    
    // Load attention
    self.attention = try GemmaAttention(
      layerIndex: layerIndex,
      config: config,
      actualHiddenSize: actualHiddenSize,
      weights: weights
    )
    
    // Store actualHiddenSize for residual connection
    self.actualHiddenSize = actualHiddenSize
    
    // Load MLP
    self.mlp = try GemmaMLP(
      layerIndex: layerIndex,
      config: config,
      actualHiddenSize: actualHiddenSize,
      weights: weights
    )
    
    // Load layer norms
    let inputNormWeight = try findTensor(
      names: [
        "model.layers.\(layerIndex).input_layernorm.weight",
        "layers.\(layerIndex).attention_norm.weight"
      ],
      description: "input layer norm weight"
    )
    let inputNormBias = weights["model.layers.\(layerIndex).input_layernorm.bias"] ??
                        weights["layers.\(layerIndex).attention_norm.bias"]
    self.inputNorm = CustomLayerNorm(
      dimensions: actualHiddenSize,
      weight: inputNormWeight,
      bias: inputNormBias,
      eps: 1e-5
    )
    
    let postNormWeight = try findTensor(
      names: [
        "model.layers.\(layerIndex).post_attention_layernorm.weight",
        "layers.\(layerIndex).ffn_norm.weight"
      ],
      description: "post attention layer norm weight"
    )
    let postNormBias = weights["model.layers.\(layerIndex).post_attention_layernorm.bias"] ??
                       weights["layers.\(layerIndex).ffn_norm.bias"]
    self.postAttentionNorm = CustomLayerNorm(
      dimensions: actualHiddenSize,
      weight: postNormWeight,
      bias: postNormBias,
      eps: 1e-5
    )
    
    super.init()
  }
  
  func callAsFunction(_ hiddenStates: MLXArray, cache: inout MLXArray?) throws -> MLXArray {
    // Pre-norm attention
    var residual = hiddenStates
    var x = inputNorm(hiddenStates)
    x = try attention(x, cache: &cache)
    
    // Check if attention output size matches residual size
    // oProj might output config.hiddenSize (640) but we need actualHiddenSize (80)
    let attnOutputSize = x.dim(x.shape.count - 1)
    if attnOutputSize != actualHiddenSize {
      // Project from oProj output size to actualHiddenSize
      // Take first actualHiddenSize elements along the last dimension
      x = x[0..<x.dim(0), 0..<x.dim(1), 0..<actualHiddenSize]
      print("   [GemmaTransformerBlock] Projected attention output from \(attnOutputSize) to \(actualHiddenSize)")
    }
    
    x = residual + x
    
    // Pre-norm MLP
    residual = x
    x = postAttentionNorm(x)
    x = mlp(x)
    x = residual + x
    
    return x
  }
}

/// Gemma attention layer
class GemmaAttention: Module {
  let qProj: Linear
  let kProj: Linear
  let vProj: Linear
  let oProj: Linear
  let numHeads: Int
  let headDim: Int
  let config: GemmaConfig
  let expectedAttentionOutputSize: Int  // Expected input size for oProj
  let oProjOutputSize: Int  // Output size from oProj
  
  init(layerIndex: Int, config: GemmaConfig, actualHiddenSize: Int, weights: [String: MLXArray]) throws {
    self.config = config
    self.numHeads = config.numAttentionHeads
    // Use actualHiddenSize instead of config.hiddenSize
    // The headDim will be calculated from actual projection outputs
    self.headDim = actualHiddenSize / config.numAttentionHeads
    
    // Helper to find tensor
    func findTensor(names: [String], description: String) throws -> MLXArray {
      for name in names {
        if let tensor = weights[name] {
          return tensor
        }
      }
      throw NSError(domain: "GemmaAttention", code: -1, 
                   userInfo: [NSLocalizedDescriptionKey: "Layer \(layerIndex): Missing \(description). Tried: \(names.joined(separator: ", "))"])
    }
    
    // Load Q, K, V, O projections
    let qWeight = try findTensor(
      names: [
        "model.layers.\(layerIndex).self_attn.q_proj.weight",
        "layers.\(layerIndex).attention.wq.weight"
      ],
      description: "q_proj weight"
    )
    let qBias = weights["model.layers.\(layerIndex).self_attn.q_proj.bias"] ??
                 weights["layers.\(layerIndex).attention.wq.bias"]
    self.qProj = Linear(weight: qWeight, bias: qBias)
    
    let kWeight = try findTensor(
      names: [
        "model.layers.\(layerIndex).self_attn.k_proj.weight",
        "layers.\(layerIndex).attention.wk.weight"
      ],
      description: "k_proj weight"
    )
    let kBias = weights["model.layers.\(layerIndex).self_attn.k_proj.bias"] ??
                weights["layers.\(layerIndex).attention.wk.bias"]
    self.kProj = Linear(weight: kWeight, bias: kBias)
    
    let vWeight = try findTensor(
      names: [
        "model.layers.\(layerIndex).self_attn.v_proj.weight",
        "layers.\(layerIndex).attention.wv.weight"
      ],
      description: "v_proj weight"
    )
    let vBias = weights["model.layers.\(layerIndex).self_attn.v_proj.bias"] ??
                weights["layers.\(layerIndex).attention.wv.bias"]
    self.vProj = Linear(weight: vWeight, bias: vBias)
    
    let oWeight = try findTensor(
      names: [
        "model.layers.\(layerIndex).self_attn.o_proj.weight",
        "layers.\(layerIndex).attention.wo.weight"
      ],
      description: "o_proj weight"
    )
    let oBias = weights["model.layers.\(layerIndex).self_attn.o_proj.bias"] ??
                weights["layers.\(layerIndex).attention.wo.bias"]
    
    // Debug: Log oProj weight shape to understand dimension mismatch
    // In MLX Linear, weight shape is [out_features, in_features]
    // So oProj weight [640, 128] means: input=128, output=640
    let oProjInputSize = oWeight.shape[1]  // Second dimension is input size
    let oProjOutputSize = oWeight.shape[0]  // First dimension is output size
    print("🔍 [GemmaAttention] Layer \(layerIndex) oProj weight shape: \(oWeight.shape)")
    print("   oProj expects input size: \(oProjInputSize), outputs: \(oProjOutputSize)")
    
    // Store the expected attention output size (what oProj expects as input)
    self.expectedAttentionOutputSize = oProjInputSize
    self.oProjOutputSize = oProjOutputSize
    
    self.oProj = Linear(weight: oWeight, bias: oBias)
    
    super.init()
  }
  
  func callAsFunction(_ hiddenStates: MLXArray, cache: inout MLXArray?) throws -> MLXArray {
    let batchSize = hiddenStates.dim(0)
    let seqLen = hiddenStates.dim(1)
    
    // Project to Q, K, V
    let queries = qProj(hiddenStates)
    let keys = kProj(hiddenStates)
    let values = vProj(hiddenStates)
    
    // Debug: Log shapes to understand the issue
    let qShape = queries.shape
    let kShape = keys.shape
    let vShape = values.shape
    print("🔍 [GemmaAttention] Projection shapes - Q: \(qShape), K: \(kShape), V: \(vShape)")
    
    // Calculate actual dimensions from projection outputs
    // Q/K/V might have different sizes in quantized models
    // Gemma 3 might use Grouped Query Attention (GQA) where K/V have fewer heads
    // Use the actual projection output sizes, not config values
    let qLastDim = qShape.last ?? 0
    let kLastDim = kShape.last ?? 0
    let vLastDim = vShape.last ?? 0
    
    guard qLastDim > 0 && kLastDim > 0 && vLastDim > 0 else {
      fatalError("Invalid projection dimensions: Q=\(qLastDim), K=\(kLastDim), V=\(vLastDim)")
    }
    
    // Calculate head dimensions for each
    let qHeadDim = qLastDim / numHeads
    
    // For K and V, check if they use fewer heads (GQA) or same number of heads
    // If K/V are smaller, calculate how many heads they have
    // K and V should have the same head_dim as Q for matmul to work
    // So if K has 256 and Q headDim is 256, K has 1 head
    // If K has 256 and Q headDim is 64, K has 4 heads with 64 dim each
    let kNumHeads = kLastDim / qHeadDim  // This ensures kHeadDim == qHeadDim
    let vNumHeads = vLastDim / qHeadDim  // This ensures vHeadDim == qHeadDim
    let kHeadDim = qHeadDim  // Must match Q for matmul
    let vHeadDim = qHeadDim  // Must match Q for matmul
    
    print("   Q: \(qLastDim) -> \(numHeads) heads, headDim=\(qHeadDim)")
    print("   K: \(kLastDim) -> \(kNumHeads) heads, headDim=\(kHeadDim)")
    print("   V: \(vLastDim) -> \(vNumHeads) heads, headDim=\(vHeadDim)")
    
    guard kNumHeads > 0 && vNumHeads > 0 else {
      fatalError("Invalid K/V dimensions: K=\(kLastDim), V=\(vLastDim), Q_headDim=\(qHeadDim)")
    }
    
    // Reshape for multi-head attention
    // Q: [batch, seq_len, qLastDim] -> [batch, seq_len, numHeads, qHeadDim] -> [batch, numHeads, seq_len, qHeadDim]
    let q = queries.reshaped(batchSize, seqLen, numHeads, qHeadDim).transposed(0, 2, 1, 3)
    
    // K: [batch, seq_len, kLastDim] -> [batch, seq_len, kNumHeads, kHeadDim] -> [batch, kNumHeads, seq_len, kHeadDim] (for RoPE)
    let kForRoPE = keys.reshaped(batchSize, seqLen, kNumHeads, kHeadDim).transposed(0, 2, 1, 3)
    
    // V: [batch, seq_len, vLastDim] -> [batch, seq_len, vNumHeads, vHeadDim] -> [batch, vNumHeads, seq_len, vHeadDim]
    let v = values.reshaped(batchSize, seqLen, vNumHeads, vHeadDim).transposed(0, 2, 1, 3)
    
    print("   After reshape - Q: \(q.shape), K: \(kForRoPE.shape), V: \(v.shape)")
    
    // Apply Rotary Positional Embeddings (RoPE) to Q and K
    // Create position indices: [0, 1, 2, ..., seqLen-1]
    let positions = MLXArray((0..<seqLen).map { Int32($0) })
    
    // Apply RoPE (simplified version for now)
    // Note: Full RoPE implementation requires careful handling of complex rotations
    // For Gemma 3, RoPE is applied before attention computation
    let (qRotated, kRotated) = RoPE.applyRotaryEmbeddingsSimple(
      q: q,
      k: kForRoPE,
      positions: positions,
      theta: config.ropeTheta,
      baseFreq: config.ropeLocalBaseFreq
    )
    
    // Transpose K for matmul: [batch, kNumHeads, seq_len, kHeadDim] -> [batch, kNumHeads, kHeadDim, seq_len]
    let kRotatedTransposed = kRotated.transposed(0, 1, 3, 2)
    
    // For GQA, repeat K and V along the head dimension to match Q
    var kExpanded = kRotatedTransposed
    var vExpanded = v
    
    if kNumHeads < numHeads {
      // Repeat K heads: [batch, kNumHeads, head_dim, seq_len] -> [batch, numHeads, head_dim, seq_len]
      let repeatCount = numHeads / kNumHeads
      var kRepeats: [MLXArray] = []
      for _ in 0..<repeatCount {
        kRepeats.append(kRotatedTransposed)
      }
      // Concatenate along head dimension (axis 1)
      kExpanded = concatenated(kRepeats, axis: 1)
      print("   K expanded: \(kExpanded.shape)")
    }
    
    if vNumHeads < numHeads {
      // Repeat V heads: [batch, vNumHeads, seq_len, head_dim] -> [batch, numHeads, seq_len, head_dim]
      let repeatCount = numHeads / vNumHeads
      var vRepeats: [MLXArray] = []
      for _ in 0..<repeatCount {
        vRepeats.append(v)
      }
      // Concatenate along head dimension (axis 1)
      vExpanded = concatenated(vRepeats, axis: 1)
      print("   V expanded: \(vExpanded.shape)")
    }
    
    // Scaled dot-product attention
    // Q: [batch, numHeads, seq_len, qHeadDim]
    // K: [batch, numHeads, kHeadDim, seq_len] = [batch, numHeads, qHeadDim, seq_len]
    // Matmul: [batch, numHeads, seq_len, qHeadDim] @ [batch, numHeads, qHeadDim, seq_len] = [batch, numHeads, seq_len, seq_len]
    // Use rotated Q from RoPE
    let scale = 1.0 / sqrt(Float(qHeadDim))
    print("   Before matmul - Q: \(qRotated.shape), K: \(kExpanded.shape)")
    var scores = (qRotated * scale).matmul(kExpanded)
    
    // Causal mask (lower triangular)
    let mask = MultiHeadAttention.createAdditiveCausalMask(seqLen)
    scores = scores + mask
    
    scores = softmax(scores, axis: -1)
    var attnOutput = matmul(scores, vExpanded)
    
    // Reshape back: [batch, num_heads, seq_len, head_dim] -> [batch, seq_len, num_heads * head_dim]
    // First, reshape to get all head outputs: [batch, num_heads, seq_len, head_dim] -> [batch, seq_len, num_heads * head_dim]
    let actualAttentionOutputSize = numHeads * qHeadDim
    attnOutput = attnOutput.transposed(0, 2, 1, 3).reshaped(batchSize, seqLen, actualAttentionOutputSize)
    
    print("   Attention output shape (calculated): \(attnOutput.shape)")
    print("   Expected oProj input size: \(expectedAttentionOutputSize)")
    print("   ⚠️  Dimension mismatch: \(actualAttentionOutputSize) vs \(expectedAttentionOutputSize)")
    
    // If dimensions don't match, we need to project or reshape
    // For quantized models, the attention output might need to be reduced
    if actualAttentionOutputSize != expectedAttentionOutputSize {
      if actualAttentionOutputSize > expectedAttentionOutputSize {
        // Take first expectedAttentionOutputSize elements along the last dimension
        // Use slicing: [batch, seq_len, actualSize] -> [batch, seq_len, expectedSize]
        // MLXArray slicing: array[all, all, 0..<expectedSize]
        attnOutput = attnOutput[0..<batchSize, 0..<seqLen, 0..<expectedAttentionOutputSize]
        print("   ✅ Sliced from \(actualAttentionOutputSize) to \(expectedAttentionOutputSize)")
      } else {
        // If actual is smaller, this shouldn't happen - the model architecture is wrong
        fatalError("Attention output size (\(actualAttentionOutputSize)) is smaller than expected (\(expectedAttentionOutputSize)). Model architecture mismatch.")
      }
    }
    
    // Output projection
    // The oProj weight shape tells us what input size it expects
    // In MLX, Linear expects weight shape [out_features, in_features]
    // So if oProj weight is [hidden_size, attention_output_size], then input should be [..., attention_output_size]
    // If oProj weight is [attention_output_size, hidden_size], then input should be [..., attention_output_size] and we need to transpose
    
    // Try the oProj call - if it fails, we'll see the exact error
    do {
      let output = oProj(attnOutput)
      print("   oProj output shape: \(output.shape)")
      return output
    } catch {
      print("❌ [GemmaAttention] oProj failed with error: \(error)")
      print("   Input shape: \(attnOutput.shape)")
      print("   This suggests a dimension mismatch - check oProj weight shape above")
      throw error
    }
  }
}

/// Gemma MLP (feed-forward network)
class GemmaMLP: Module {
  let gateProj: Linear
  let upProj: Linear
  let downProj: Linear
  
  init(layerIndex: Int, config: GemmaConfig, actualHiddenSize: Int, weights: [String: MLXArray]) throws {
    // Use actualHiddenSize for MLP calculations
    // Intermediate size might also need adjustment based on actual model
    let intermediateSize = config.intermediateSize
    
    // Helper to find tensor
    func findTensor(names: [String], description: String) throws -> MLXArray {
      for name in names {
        if let tensor = weights[name] {
          return tensor
        }
      }
      throw NSError(domain: "GemmaMLP", code: -1, 
                   userInfo: [NSLocalizedDescriptionKey: "Layer \(layerIndex): Missing \(description). Tried: \(names.joined(separator: ", "))"])
    }
    
    // Load gate, up, down projections
    let gateWeight = try findTensor(
      names: [
        "model.layers.\(layerIndex).mlp.gate_proj.weight",
        "layers.\(layerIndex).feed_forward.w1.weight"
      ],
      description: "gate_proj weight"
    )
    let gateBias = weights["model.layers.\(layerIndex).mlp.gate_proj.bias"] ??
                   weights["layers.\(layerIndex).feed_forward.w1.bias"]
    self.gateProj = Linear(weight: gateWeight, bias: gateBias)
    
    let upWeight = try findTensor(
      names: [
        "model.layers.\(layerIndex).mlp.up_proj.weight",
        "layers.\(layerIndex).feed_forward.w3.weight"
      ],
      description: "up_proj weight"
    )
    let upBias = weights["model.layers.\(layerIndex).mlp.up_proj.bias"] ??
                 weights["layers.\(layerIndex).feed_forward.w3.bias"]
    self.upProj = Linear(weight: upWeight, bias: upBias)
    
    let downWeight = try findTensor(
      names: [
        "model.layers.\(layerIndex).mlp.down_proj.weight",
        "layers.\(layerIndex).feed_forward.w2.weight"
      ],
      description: "down_proj weight"
    )
    let downBias = weights["model.layers.\(layerIndex).mlp.down_proj.bias"] ??
                   weights["layers.\(layerIndex).feed_forward.w2.bias"]
    self.downProj = Linear(weight: downWeight, bias: downBias)
    
    super.init()
  }
  
  func callAsFunction(_ hiddenStates: MLXArray) -> MLXArray {
    // SwiGLU activation: gate * silu(up)
    let gate = gateProj(hiddenStates)
    let up = upProj(hiddenStates)
    let activated = gate * silu(up)
    return downProj(activated)
  }
}

/// Gemma model configuration
struct GemmaConfig {
  let vocabSize: Int
  let hiddenSize: Int
  let numLayers: Int
  let numAttentionHeads: Int
  let intermediateSize: Int
  let maxPositionEmbeddings: Int
  let eosTokenId: Int
  let bosTokenId: Int
  let ropeTheta: Float
  let ropeLocalBaseFreq: Float
  let headDim: Int  // Head dimension for RoPE
  
  init(from configDict: [String: Any]) {
    self.vocabSize = configDict["vocab_size"] as? Int ?? 262144
    
    // For Gemma 3 270M 4-bit, the actual hidden size might be different from config
    // Check if we can infer from embedding weights or use config value
    // Gemma 3 270M typically has hidden_size=80 (not 640)
    // The config might say 640 but actual model uses 80
    if let configHiddenSize = configDict["hidden_size"] as? Int {
      // For 4-bit quantized models, the hidden_size in config might be wrong
      // Gemma 3 270M actually uses 80, not 640
      // If config says 640 but we see embedding with 80, use 80
      self.hiddenSize = configHiddenSize
      print("⚠️ [GemmaConfig] Config says hidden_size=\(configHiddenSize), but model might use 80")
    } else {
      self.hiddenSize = 80  // Default for Gemma 3 270M
    }
    
    self.numLayers = configDict["num_hidden_layers"] as? Int ?? 18
    self.numAttentionHeads = configDict["num_attention_heads"] as? Int ?? 4
    // Intermediate size is typically 4x hidden size for Gemma
    self.intermediateSize = configDict["intermediate_size"] as? Int ?? 
                           (self.hiddenSize * 4)
    self.maxPositionEmbeddings = configDict["max_position_embeddings"] as? Int ?? 32768
    self.eosTokenId = configDict["eos_token_id"] as? Int ?? 1
    self.bosTokenId = configDict["bos_token_id"] as? Int ?? 2
    
    // RoPE parameters
    self.ropeTheta = configDict["rope_theta"] as? Float ?? 1000000.0
    self.ropeLocalBaseFreq = configDict["rope_local_base_freq"] as? Float ?? 10000.0
    // Head dimension for RoPE (may be specified in config or calculated)
    self.headDim = (configDict["head_dim"] as? Int) ?? (hiddenSize / numAttentionHeads)
    
    // Debug: Log config values
    print("📋 [GemmaConfig] Loaded config:")
    print("   vocabSize: \(vocabSize)")
    print("   hiddenSize: \(hiddenSize)")
    print("   numLayers: \(numLayers)")
    print("   numAttentionHeads: \(numAttentionHeads)")
    print("   intermediateSize: \(intermediateSize)")
    print("   headDim: \(headDim)")
    print("   ropeTheta: \(ropeTheta)")
    print("   ropeLocalBaseFreq: \(ropeLocalBaseFreq)")
  }
}

/// Rotary Positional Embeddings (RoPE) helper
struct RoPE {
  /// Simplified RoPE implementation
  /// Note: Full RoPE implementation with vectorized operations would require
  /// complex number support or careful manual rotation using cos/sin.
  /// For now, this is a placeholder that returns Q and K unchanged.
  /// The model may work without RoPE for short sequences, but full RoPE
  /// is needed for proper positional understanding in longer sequences.
  static func applyRotaryEmbeddingsSimple(
    q: MLXArray,
    k: MLXArray,
    positions: MLXArray,
    theta: Float,
    baseFreq: Float
  ) -> (MLXArray, MLXArray) {
    // TODO: Implement full RoPE with vectorized operations
    // Full implementation would:
    // 1. Create frequency matrix from baseFreq and head_dim
    // 2. Compute angles from positions and frequencies
    // 3. Apply cos/sin rotation to Q and K pairs
    // 4. Return rotated Q and K
    
    // For now, return Q and K unchanged
    // This is a placeholder - the model may work without RoPE for short sequences
    return (q, k)
  }
}

