//
//  QuantizationUtils.swift
//  GemmaTestAppFeature
//
//  4-bit quantization/dequantization utilities for Phi-3
//

import Foundation
import MLX

/// Dequantizes a 4-bit quantized weight tensor
struct QuantizationUtils {
    
    /// Dequantize a 4-bit weight using scales and biases
    /// - Parameters:
    ///   - weight: Quantized weight tensor (uint32 packed 4-bit values)
    ///   - scales: Per-group scaling factors
    ///   - biases: Per-group zero points/biases
    /// - Returns: Dequantized float32 tensor with full dimensions
    static func dequantize4Bit(
        weight: MLXArray,
        scales: MLXArray,
        biases: MLXArray
    ) -> MLXArray {
        // Convert to float32 for computation
        let weightFloat = weight.asType(.float32)
        let scalesFloat = scales.asType(.float32)
        let biasesFloat = biases.asType(.float32)
        
        // Dequantization formula: full_weight = weight * scales + biases
        // The scales and biases are per-group (typically groups of 128 or 64)
        
        let weightShape = weightFloat.shape
        let scalesShape = scalesFloat.shape
        
        print("   [Dequant] Weight shape: \(weightShape), Scales shape: \(scalesShape)")
        
        // For MLX-quantized models, scales/biases are typically per output channel
        // We need to broadcast them correctly
        
        // Simple approach: broadcast scales and biases to match weight shape
        // This assumes scales/biases are [out_features, ...] and weight is [out_features, in_features]
        
        // For MLX quantized models, typically:
        // weight: [out_features, in_features_quantized]
        // scales/biases: [out_features, num_groups] where num_groups = in_features_quantized
        //
        // Dequantization: expand each group by the quantization factor (typically 8 for 4-bit)
        
        if scalesShape.count == 2 && weightShape.count == 2 {
            let outFeatures = weightShape[0]
            let inFeaturesQuant = weightShape[1]
            let numGroups = scalesShape[1]
            
            // Check if they match (no expansion needed)
            if inFeaturesQuant == numGroups {
                // Direct broadcast: scales/biases already match weight dimensions
                print("   [Dequant] Direct broadcast (dimensions match)")
                let dequantized = weightFloat * scalesFloat + biasesFloat
                print("   [Dequant] Dequantized shape: \(dequantized.shape)")
                return dequantized
            } else {
                // Need to expand: typically inFeaturesQuant * groupSize = full_dimension
                let groupSize = inFeaturesQuant / numGroups
                print("   [Dequant] Expanding with group size: \(groupSize)")
                
                // Use repeat to expand scales/biases
                // MLX repeat: repeat(array, repeats, axis)
                let scalesExpanded = MLX.repeated(scalesFloat, count: groupSize, axis: 1)
                let biasesExpanded = MLX.repeated(biasesFloat, count: groupSize, axis: 1)
                
                let dequantized = weightFloat * scalesExpanded + biasesExpanded
                print("   [Dequant] Dequantized shape: \(dequantized.shape)")
                return dequantized
            }
        } else {
            // Fallback: try simple broadcast
            print("   [Dequant] Using simple broadcast (shapes: weight=\(weightShape), scales=\(scalesShape))")
            let dequantized = weightFloat * scalesFloat + biasesFloat
            return dequantized
        }
    }
    
    /// Dequantize all weights in a weight dictionary
    /// - Parameter weights: Dictionary of weight tensors
    /// - Returns: Dictionary with dequantized weights
    static func dequantizeWeights(_ weights: [String: MLXArray]) -> [String: MLXArray] {
        var dequantized: [String: MLXArray] = [:]
        
        print("🔧 [QuantizationUtils] Dequantizing weights...")
        
        // Find all weight tensors that have corresponding scales/biases
        var processedKeys = Set<String>()
        
        for (key, value) in weights {
            if key.hasSuffix(".weight") {
                let baseKey = String(key.dropLast(".weight".count))
                let scalesKey = baseKey + ".scales"
                let biasesKey = baseKey + ".biases"
                
                if let scales = weights[scalesKey], let biases = weights[biasesKey] {
                    // Quantized weight - dequantize it
                    print("   Dequantizing \(key)...")
                    let dequantizedWeight = dequantize4Bit(weight: value, scales: scales, biases: biases)
                    dequantized[key] = dequantizedWeight
                    
                    // Mark as processed
                    processedKeys.insert(key)
                    processedKeys.insert(scalesKey)
                    processedKeys.insert(biasesKey)
                } else {
                    // Non-quantized weight (like layer norms)
                    dequantized[key] = value
                    processedKeys.insert(key)
                }
            }
        }
        
        // Copy over any remaining tensors (scales/biases are not needed after dequantization)
        for (key, value) in weights {
            if !processedKeys.contains(key) && !key.hasSuffix(".scales") && !key.hasSuffix(".biases") {
                dequantized[key] = value
            }
        }
        
        print("✅ [QuantizationUtils] Dequantization complete: \(dequantized.count) tensors")
        
        return dequantized
    }
}

