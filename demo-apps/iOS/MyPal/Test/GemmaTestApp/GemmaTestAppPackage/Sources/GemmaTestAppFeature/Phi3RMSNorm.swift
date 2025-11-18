//
//  Phi3RMSNorm.swift
//  GemmaTestAppFeature
//
//  RMSNorm implementation for Phi-3
//  Formula: output = x * weight / sqrt(mean(x^2) + eps)
//

import Foundation
import MLX
import MLXFast

/// RMSNorm layer for Phi-3
struct Phi3RMSNorm {
    let weight: MLXArray  // [actual_hidden_dim]
    let eps: Float
    
    init(weight: MLXArray, eps: Float = 1e-5) {
        self.weight = weight
        self.eps = eps
    }
    
    /// Apply RMSNorm to input
    /// - Parameter x: Input tensor [..., hidden_dim]
    /// - Returns: Normalized output [..., hidden_dim]
    func callAsFunction(_ x: MLXArray) -> MLXArray {
        let hiddenDim = x.shape[x.shape.count - 1]
        
        // Check if weight shape matches
        if weight.shape[0] != hiddenDim {
            print("⚠️  [Phi3RMSNorm] Weight shape mismatch: expected \(hiddenDim), got \(weight.shape[0]). Skipping norm.")
            return x
        }
        
        // Compute mean of squares: mean(x^2)
        let xSquared = x * x
        let meanSquared = mean(xSquared, axes: [-1], keepDims: true)
        
        // Compute RMS: sqrt(mean(x^2) + eps)
        let rms = sqrt(meanSquared + eps)
        
        // Normalize: x / rms
        let normalized = x / rms
        
        // Apply weight scaling
        let output = normalized * weight
        
        return output
    }
}

// Helper to create RMSNorm from config
func createRMSNorm(from weights: [String: MLXArray], layerIdx: Int, config: Phi3Config) -> Phi3RMSNorm? {
    // Try to find input layernorm weight
    let normKey = "model.layers.\(layerIdx).input_layernorm.weight"
    
    guard let normWeight = weights[normKey] else {
        return nil
    }
    
    return Phi3RMSNorm(weight: normWeight, eps: config.rmsNormEps)
}

/// Create post-attention RMSNorm
func createPostAttnRMSNorm(from weights: [String: MLXArray], layerIdx: Int, config: Phi3Config) -> Phi3RMSNorm? {
    let normKey = "model.layers.\(layerIdx).post_attention_layernorm.weight"
    
    guard let normWeight = weights[normKey] else {
        return nil
    }
    
    return Phi3RMSNorm(weight: normWeight, eps: config.rmsNormEps)
}

/// Create final RMSNorm (before LM head)
func createFinalRMSNorm(from weights: [String: MLXArray], config: Phi3Config) -> Phi3RMSNorm? {
    guard let normWeight = weights["model.norm.weight"] else {
        return nil
    }
    
    return Phi3RMSNorm(weight: normWeight, eps: config.rmsNormEps)
}

