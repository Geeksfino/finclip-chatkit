//
//  Phi3MLP.swift
//  GemmaTestAppFeature
//
//  Feed-forward MLP layer for Phi-3 with GELU activation
//

import Foundation
import MLX
import MLXFast

/// MLP layer for Phi-3
struct Phi3MLP {
    let gateUpProj: MLXArray?  // Combined: [2*intermediate, hidden] (for float16)
    let gateProj: MLXArray?    // Separate gate: [intermediate, hidden] (for quantized)
    let upProj: MLXArray?      // Separate up: [intermediate, hidden]
    let downProj: MLXArray     // [hidden, intermediate]
    let useCombinedGateUp: Bool
    
    init?(
        layerIdx: Int,
        actualHiddenDim: Int,
        weights: [String: MLXArray]
    ) {
        let downKey = "model.layers.\(layerIdx).mlp.down_proj.weight"
        guard let downW = weights[downKey] else {
            print("⚠️  [Phi3MLP] Layer \(layerIdx) missing down_proj weight")
            return nil
        }
        self.downProj = downW.asType(.float32)
        
        // Check for combined gate_up projection first (Phi-3 float16 format)
        let gateUpKey = "model.layers.\(layerIdx).mlp.gate_up_proj.weight"
        
        if let gateUpW = weights[gateUpKey] {
            // Combined gate_up projection - keep as single tensor
            self.gateUpProj = gateUpW.asType(.float32)
            self.gateProj = nil
            self.upProj = nil
            self.useCombinedGateUp = true
            
            if layerIdx < 2 {
                print("   ✓ Layer \(layerIdx): Using combined gate_up_proj (shape: \(gateUpW.shape))")
            }
        } else {
            // Try separate gate and up projections (quantized format)
            let gateKey = "model.layers.\(layerIdx).mlp.gate_proj.weight"
            let upKey = "model.layers.\(layerIdx).mlp.up_proj.weight"
            
            guard let gateW = weights[gateKey],
                  let upW = weights[upKey] else {
                print("⚠️  [Phi3MLP] Layer \(layerIdx) missing MLP weights")
                return nil
            }
            
            // Check shapes match
            if gateW.shape[1] != actualHiddenDim {
                print("⚠️  [Phi3MLP] Gate weight shape mismatch: expected input \(actualHiddenDim), got \(gateW.shape[1])")
                return nil
            }
            
            self.gateUpProj = nil
            self.gateProj = gateW.asType(.float32)
            self.upProj = upW.asType(.float32)
            self.useCombinedGateUp = false
            
            if layerIdx < 2 {
                print("   ✓ Layer \(layerIdx): Using separate gate/up_proj")
            }
        }
    }
    
    /// Apply MLP with SiLU activation (Phi-3 uses SiLU, not GELU!)
    /// - Parameter x: Input [batch, seq_len, hidden]
    /// - Returns: MLP output [batch, seq_len, hidden]
    func callAsFunction(_ x: MLXArray) -> MLXArray {
        let xFloat = x.asType(.float32)
        
        // Gate and up projections
        let gateOut: MLXArray
        let upOut: MLXArray
        
        if useCombinedGateUp, let gateUpW = gateUpProj {
            // Combined gate_up: project first, then split output
            // gateUpW shape: [2*intermediate, hidden] = [16384, 3072]
            // Project: [batch, seq, hidden] @ [hidden, 2*intermediate] = [batch, seq, 2*intermediate]
            guard let gateUp = try? matmul(xFloat, gateUpW.T) else {
                print("⚠️  [Phi3MLP] Gate-up projection failed")
                return x
            }
            
            // Split output: [batch, seq, 2*intermediate] -> gate, up each [batch, seq, intermediate]
            let intermediateSize = gateUp.shape[2] / 2
            gateOut = gateUp[0..., 0..., 0..<intermediateSize]
            upOut = gateUp[0..., 0..., intermediateSize..<(2*intermediateSize)]
        } else if let gateW = gateProj, let upW = upProj {
            // Separate gate and up projections
            guard let gate = try? matmul(xFloat, gateW.T),
                  let up = try? matmul(xFloat, upW.T) else {
                print("⚠️  [Phi3MLP] Projection failed")
                return x
            }
            gateOut = gate
            upOut = up
        } else {
            print("⚠️  [Phi3MLP] No gate/up weights available")
            return x
        }
        
        // Apply SiLU to gate, multiply with up (SwiGLU: gate * silu(up) or silu(gate) * up)
        // Phi-3 uses: silu(gate) * up
        let gateActivated = silu(gateOut)
        let combined = gateActivated * upOut
        
        // Down projection
        guard let output = try? matmul(combined, downProj.T) else {
            print("⚠️  [Phi3MLP] Down projection failed")
            return x
        }
        
        return output
    }
}

/// Create MLP for a layer
func createPhi3MLP(
    layerIdx: Int,
    actualHiddenDim: Int,
    weights: [String: MLXArray]
) -> Phi3MLP? {
    return Phi3MLP(layerIdx: layerIdx, actualHiddenDim: actualHiddenDim, weights: weights)
}

