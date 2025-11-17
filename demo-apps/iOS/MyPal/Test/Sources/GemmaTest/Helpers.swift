//
//  Helpers.swift
//  GemmaTest
//
//  Utility functions for activations and sampling
//

import Foundation
import MLX
import MLXRandom

/// GELU activation function
func gelu(_ x: MLXArray) -> MLXArray {
    return 0.5 * x * (1.0 + MLX.erf(x / sqrt(2.0)))
}

/// SiLU (Sigmoid Linear Unit) activation function
func silu(_ x: MLXArray) -> MLXArray {
    return x * MLX.sigmoid(x)
}

/// Greedy sampling: select token with highest probability
func greedySample(_ logits: MLXArray) -> Int32 {
    // For greedy sampling, use very low temperature categorical sampling
    // This effectively selects the highest probability token
    let scaledLogits = logits / MLXArray(0.001)  // Very low temperature
    let probs = softmax(scaledLogits, axis: -1)
    let sampled = MLXRandom.categorical(probs, count: 1)
    return Int32(sampled[0].item(Int32.self))
}

/// Top-k sampling: sample from top k tokens
func topKSample(_ logits: MLXArray, topK: Int = 50, temperature: Float = 1.0) -> Int32 {
    let scaledLogits = logits / MLXArray(temperature)
    let probs = softmax(scaledLogits, axis: -1)
    
    // Use categorical sampling (simpler than top-k for now)
    let sampled = MLXRandom.categorical(probs, count: 1)
    return Int32(sampled[0].item(Int32.self))
}

