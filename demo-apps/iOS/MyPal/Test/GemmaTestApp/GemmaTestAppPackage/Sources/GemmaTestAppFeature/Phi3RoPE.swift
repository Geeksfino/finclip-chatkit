//
//  Phi3RoPE.swift
//  GemmaTestAppFeature
//
//  Rotary Position Embeddings (RoPE) for Phi-3
//  Applies rotational matrices to Q and K tensors based on position
//

import Foundation
import MLX
import MLXFast

/// Phi-3 RoPE implementation
struct Phi3RoPE {
    let ropeTheta: Float
    let headDim: Int
    
    init(ropeTheta: Float = 10000.0, headDim: Int) {
        self.ropeTheta = ropeTheta
        self.headDim = headDim
    }
    
    /// Apply RoPE to Q and K tensors
    /// - Parameters:
    ///   - q: Query tensor [batch, num_heads, seq_len, head_dim]
    ///   - k: Key tensor [batch, num_heads, seq_len, head_dim]
    /// - Returns: Tuple of (q_rotated, k_rotated)
    func apply(q: MLXArray, k: MLXArray) -> (MLXArray, MLXArray) {
        let seqLen = q.shape[2]
        
        // Compute frequencies: theta_i = rope_theta ^ (-2i/d)
        let invFreq = computeInverseFrequencies()
        
        // Compute angles: m * theta where m is position and theta is frequency
        let angles = computeAngles(seqLen: seqLen, invFreq: invFreq)
        
        // Create cos and sin matrices
        let cosValues = MLX.cos(angles)
        let sinValues = MLX.sin(angles)
        
        // Reshape for broadcasting: [seq_len, head_dim] -> [1, 1, seq_len, head_dim]
        let cosBcast = cosValues.reshaped([1, 1, seqLen, headDim])
        let sinBcast = sinValues.reshaped([1, 1, seqLen, headDim])
        
        // Split Q and K into even/odd for rotation
        let qRot = rotateHalf(q, sin: sinBcast, cos: cosBcast)
        let kRot = rotateHalf(k, sin: sinBcast, cos: cosBcast)
        
        return (qRot, kRot)
    }
    
    private func computeInverseFrequencies() -> MLXArray {
        var freqs: [Float] = []
        for i in 0..<(headDim / 2) {
            let exponent = -2.0 * Float(i) / Float(headDim)
            let freq = pow(ropeTheta, exponent)
            freqs.append(freq)
        }
        // Interleave for rotary embeddings: [f0, f0, f1, f1, ...]
        var interleaved: [Float] = []
        for freq in freqs {
            interleaved.append(freq)
            interleaved.append(freq)
        }
        return MLXArray(interleaved)
    }
    
    private func computeAngles(seqLen: Int, invFreq: MLXArray) -> MLXArray {
        // Create position indices: [0, 1, 2, ..., seqLen-1]
        let positions = (0..<seqLen).map { Float($0) }
        
        // Outer product: positions x invFreq -> [seqLen, head_dim]
        var angles: [Float] = []
        for pos in positions {
            for freq in 0..<headDim {
                let angle = pos * invFreq[freq].item() as! NSNumber
                angles.append(angle.floatValue)
            }
        }
        
        return MLXArray(angles).reshaped([seqLen, headDim])
    }
    
    private func rotateHalf(_ tensor: MLXArray, sin: MLXArray, cos: MLXArray) -> MLXArray {
        // Split tensor into even and odd
        let dim = headDim / 2
        
        // x[..., :d/2] and x[..., d/2:]
        let x1 = tensor[0..<tensor.dim(0), 0..<tensor.dim(1), 0..<tensor.dim(2), 0..<dim]
        let x2 = tensor[0..<tensor.dim(0), 0..<tensor.dim(1), 0..<tensor.dim(2), dim..<headDim]
        
        // Split sin and cos
        let sinPart = sin[0..<sin.dim(2), 0..<dim]
        let cosPart = cos[0..<cos.dim(2), 0..<dim]
        
        // Apply rotation: (x1*cos - x2*sin), (x1*sin + x2*cos)
        let rotated1 = x1 * cosPart - x2 * sinPart
        let rotated2 = x1 * sinPart + x2 * cosPart
        
        // Concatenate back
        let result = concatenated([rotated1, rotated2], axis: -1)
        
        return result
    }
}

