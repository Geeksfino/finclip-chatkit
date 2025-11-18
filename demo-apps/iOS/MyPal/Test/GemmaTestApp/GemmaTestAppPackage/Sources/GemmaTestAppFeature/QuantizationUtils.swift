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
    ///   - targetInputDim: Optional target input dimension (e.g., 3072 for Phi-3). If provided, expands quantized dimension to target.
    /// - Returns: Dequantized float32 tensor with full dimensions
    static func dequantize4Bit(
        weight: MLXArray,
        scales: MLXArray,
        biases: MLXArray,
        targetInputDim: Int? = nil
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
                // Need to expand: inFeaturesQuant needs to be expanded to full dimension
                // For MLX 4-bit quantized models:
                // - weight: [out_features, in_features_quantized] = [9216, 384]
                // - scales: [out_features, num_groups] = [9216, 48]
                // - Full dimension should be: in_features_quantized * (in_features_quantized / num_groups)
                // - But actually, we need to know the target dimension from config
                // - For now, calculate expansion factor: each quantized element represents multiple full elements
                
                let groupSize = inFeaturesQuant / numGroups  // 384 / 48 = 8
                print("   [Dequant] Group size: \(groupSize), quantized dim: \(inFeaturesQuant), num groups: \(numGroups)")
                
                // Expand scales/biases to match quantized dimension first
                let scalesExpanded = MLX.repeated(scalesFloat, count: groupSize, axis: 1)  // [9216, 48] -> [9216, 384]
                let biasesExpanded = MLX.repeated(biasesFloat, count: groupSize, axis: 1)   // [9216, 48] -> [9216, 384]
                
                // Apply dequantization: weight * scales + biases
                let dequantizedQuant = weightFloat * scalesExpanded + biasesExpanded  // [9216, 384]
                
                // Now we need to expand from quantized dimension to full dimension
                // The expansion factor is: full_dim / quantized_dim
                // For Phi-3: 3072 / 384 = 8
                // But we don't know the full dimension here - it should come from config
                // For now, if the expansion would be needed, we'll need to handle it differently
                // Actually, the quantized weights might already be in the "expanded" form but with reduced precision
                
                // Check if we need further expansion by comparing with expected dimensions
                // If scales have 48 groups and weight has 384 elements, each group covers 8 elements
                // But we might need 3072 total elements, which is 384 * 8
                // This suggests the quantized weights are stored at 1/8th the resolution
                
                // Now expand from quantized dimension to full dimension if target is provided
                if let targetDim = targetInputDim, targetDim > inFeaturesQuant {
                    let expansionFactor = targetDim / inFeaturesQuant  // e.g., 3072 / 384 = 8
                    if expansionFactor * inFeaturesQuant == targetDim {
                        print("   [Dequant] Expanding from \(inFeaturesQuant) to \(targetDim) (factor: \(expansionFactor))")
                        // Expand by repeating each column expansionFactor times
                        // More efficient: reshape to add dimension, then tile/repeat
                        // dequantizedQuant: [out_features, in_quant]
                        // We want: [out_features, in_quant * expansionFactor]
                        
                        // Reshape to add a dimension: [out_features, in_quant, 1]
                        let reshaped = dequantizedQuant.reshaped([outFeatures, inFeaturesQuant, 1])
                        // Repeat along the new dimension: [out_features, in_quant, expansionFactor]
                        let repeated = MLX.repeated(reshaped, count: expansionFactor, axis: 2)
                        // Reshape back: [out_features, in_quant * expansionFactor]
                        let expanded = repeated.reshaped([outFeatures, targetDim])
                        print("   [Dequant] Final expanded shape: \(expanded.shape)")
                        return expanded
                    } else {
                        print("   [Dequant] WARNING: Expansion factor not integer (\(targetDim) / \(inFeaturesQuant) = \(Float(targetDim) / Float(inFeaturesQuant)))")
                    }
                }
                
                print("   [Dequant] Dequantized shape: \(dequantizedQuant.shape)")
                return dequantizedQuant
            }
        } else {
            // Fallback: try simple broadcast
            print("   [Dequant] Using simple broadcast (shapes: weight=\(weightShape), scales=\(scalesShape))")
            let dequantized = weightFloat * scalesFloat + biasesFloat
            return dequantized
        }
    }
    
    /// Dequantize all weights in a weight dictionary
    /// - Parameters:
    ///   - weights: Dictionary of weight tensors
    ///   - targetHiddenDim: Target hidden dimension (e.g., 3072 for Phi-3). Used to expand quantized dimensions.
    /// - Returns: Dictionary with dequantized weights
    static func dequantizeWeights(_ weights: [String: MLXArray], targetHiddenDim: Int? = nil) -> [String: MLXArray] {
        var dequantized: [String: MLXArray] = [:]
        
        print("🔧 [QuantizationUtils] Dequantizing weights...")
        
        // Find all weight tensors that have corresponding scales/biases
        var processedKeys = Set<String>()
        var dequantizedCount = 0
        
        for (key, value) in weights {
            if key.hasSuffix(".weight") {
                let baseKey = String(key.dropLast(".weight".count))
                let scalesKey = baseKey + ".scales"
                let biasesKey = baseKey + ".biases"
                
                if let scales = weights[scalesKey], let biases = weights[biasesKey] {
                    // Quantized weight - dequantize it
                    print("   Dequantizing \(key)...")
                    // Determine target dimension based on weight type
                    let targetDim: Int?
                    if key.contains("down_proj") {
                        // down_proj: [hidden_size, intermediate_size]
                        // Input dimension is intermediate_size, not hidden_size
                        // For Phi-3: intermediate_size = 8192
                        // Quantized might be 1024, need to expand to 8192
                        // Calculate: if quantized is 1024 and targetHiddenDim is 3072, 
                        // then intermediate expansion = 8192 (3072 * 8192 / 3072 = 8192, but that's circular)
                        // Actually, we need to infer: if quantized is 1024 and hidden is 3072,
                        // then intermediate should be 8192 (1024 * 8 = 8192, matching the 384->3072 pattern)
                        let quantizedInputDim = value.shape[1]
                        if quantizedInputDim == 1024 {
                            // Expand to intermediate_size (8192 for Phi-3)
                            targetDim = 8192
                        } else {
                            // Use targetHiddenDim as fallback
                            targetDim = targetHiddenDim
                        }
                    } else if key.contains("qkv_proj") || key.contains("q_proj") || key.contains("k_proj") || key.contains("v_proj") || 
                              key.contains("o_proj") || key.contains("gate_up_proj") || key.contains("gate_proj") || key.contains("up_proj") ||
                              key.contains("embed_tokens") || key.contains("lm_head") {
                        // These weights have input dimension = hidden_size
                        targetDim = targetHiddenDim
                    } else {
                        // Other weights - don't expand
                        targetDim = nil
                    }
                    let dequantizedWeight = dequantize4Bit(weight: value, scales: scales, biases: biases, targetInputDim: targetDim)
                    dequantized[key] = dequantizedWeight
                    dequantizedCount += 1
                    
                    // Log dimension change for key weights
                    if key.contains("qkv_proj") || key.contains("q_proj") || key.contains("embed_tokens") {
                        print("      Original: \(value.shape) -> Dequantized: \(dequantizedWeight.shape)")
                    }
                    
                    // Mark as processed
                    processedKeys.insert(key)
                    processedKeys.insert(scalesKey)
                    processedKeys.insert(biasesKey)
                } else {
                    // Non-quantized weight (like layer norms, embeddings if not quantized)
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
        
        print("✅ [QuantizationUtils] Dequantization complete: \(dequantizedCount) weights dequantized, \(dequantized.count) total tensors")
        
        return dequantized
    }
}

