//
//  GemmaConfig.swift
//  GemmaTest
//
//  Model configuration struct for Gemma-3-270M
//

import Foundation

struct GemmaConfig {
    let vocabSize: Int
    let hiddenSize: Int
    let numLayers: Int
    let numAttentionHeads: Int
    let numKVHeads: Int  // For GQA
    let intermediateSize: Int
    let headDim: Int
    let maxPositionEmbeddings: Int
    let eosTokenId: Int
    let bosTokenId: Int
    let padTokenId: Int
    let ropeTheta: Float
    let ropeLocalBaseFreq: Float
    let layerNormEps: Float
    
    init(from configDict: [String: Any]) {
        self.vocabSize = configDict["vocab_size"] as? Int ?? 262144
        self.hiddenSize = configDict["hidden_size"] as? Int ?? 640
        self.numLayers = configDict["num_hidden_layers"] as? Int ?? 18
        self.numAttentionHeads = configDict["num_attention_heads"] as? Int ?? 4
        
        // GQA: num_key_value_heads defaults to num_attention_heads if not specified
        if let numKV = configDict["num_key_value_heads"] as? Int {
            self.numKVHeads = numKV
        } else {
            // Default GQA ratio for Gemma-3-270M is typically 4:1
            self.numKVHeads = self.numAttentionHeads / 4
        }
        
        self.intermediateSize = configDict["intermediate_size"] as? Int ?? 2048
        
        // head_dim from config, or calculate from hidden_size / num_attention_heads
        if let hd = configDict["head_dim"] as? Int {
            self.headDim = hd
        } else {
            self.headDim = self.hiddenSize / self.numAttentionHeads
        }
        
        self.maxPositionEmbeddings = configDict["max_position_embeddings"] as? Int ?? 32768
        self.bosTokenId = configDict["bos_token_id"] as? Int ?? 2
        
        // eos_token_id can be an array or single value
        if let eosArray = configDict["eos_token_id"] as? [Int] {
            self.eosTokenId = eosArray.first ?? 1
        } else {
            self.eosTokenId = configDict["eos_token_id"] as? Int ?? 1
        }
        
        self.padTokenId = configDict["pad_token_id"] as? Int ?? 0
        self.ropeTheta = configDict["rope_theta"] as? Float ?? 1000000.0
        self.ropeLocalBaseFreq = configDict["rope_local_base_freq"] as? Float ?? 10000.0
        
        // rms_norm_eps or layer_norm_eps
        if let eps = configDict["rms_norm_eps"] as? Double {
            self.layerNormEps = Float(eps)
        } else if let eps = configDict["layer_norm_eps"] as? Double {
            self.layerNormEps = Float(eps)
        } else {
            self.layerNormEps = 1e-6
        }
        
        print("📋 [GemmaConfig] Loaded config:")
        print("   vocabSize: \(vocabSize)")
        print("   hiddenSize: \(hiddenSize)")
        print("   numLayers: \(numLayers)")
        print("   numAttentionHeads: \(numAttentionHeads)")
        print("   numKVHeads: \(numKVHeads)")
        print("   headDim: \(headDim)")
        print("   intermediateSize: \(intermediateSize)")
        print("   layerNormEps: \(layerNormEps)")
    }
}

