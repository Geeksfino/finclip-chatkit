//
//  AttentionHelpers.swift
//  GemmaTestAppFeature
//
//  Helper functions for attention mechanisms
//

import Foundation
import MLX

/// Helper class for multi-head attention operations
struct MultiHeadAttention {
    /// Create an additive causal mask for autoregressive attention
    /// Returns a mask of shape [1, 1, seqLen, seqLen] with 0 on/below diagonal, -inf above
    static func createAdditiveCausalMask(_ seqLen: Int) -> MLXArray {
        // Create a lower triangular matrix (causal mask)
        // Values below and on diagonal are 0, above diagonal are -inf
        var maskValues: [Float] = []
        for i in 0..<seqLen {
            for j in 0..<seqLen {
                if j > i {
                    // Future position - mask it out with large negative number
                    maskValues.append(-1e9)
                } else {
                    // Past or current position - allow attention
                    maskValues.append(0.0)
                }
            }
        }
        
        // Create MLXArray and reshape to [1, 1, seqLen, seqLen]
        let mask = MLXArray(maskValues).reshaped([1, 1, seqLen, seqLen])
        return mask
    }
}
