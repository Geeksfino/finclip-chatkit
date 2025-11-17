//
//  WeightLoader.swift
//  GemmaTest
//
//  Loads config.json and model.safetensors from mlx-community format
//

import Foundation
import MLX

struct WeightLoader {
    /// Loads config.json and model.safetensors from a directory
    /// Returns: (GemmaConfig, [String: MLXArray])
    static func loadFromDirectory(_ dir: String) throws -> (GemmaConfig, [String: MLXArray]) {
        let dirURL = URL(fileURLWithPath: dir)
        
        // 1) Load config.json
        let configPath = dirURL.appendingPathComponent("config.json")
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw NSError(
                domain: "WeightLoader",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing config.json at \(configPath.path)"]
            )
        }
        
        print("📋 [WeightLoader] Loading config.json...")
        let configData = try Data(contentsOf: configPath)
        guard let configDict = try JSONSerialization.jsonObject(with: configData, options: []) as? [String: Any] else {
            throw NSError(
                domain: "WeightLoader",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse config.json"]
            )
        }
        
        let config = GemmaConfig(from: configDict)
        
        // 2) Load model.safetensors (single-file layout)
        let safetensorsPath = dirURL.appendingPathComponent("model.safetensors")
        guard FileManager.default.fileExists(atPath: safetensorsPath.path) else {
            throw NSError(
                domain: "WeightLoader",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Missing model.safetensors at \(safetensorsPath.path)"]
            )
        }
        
        print("⚖️  [WeightLoader] Loading model.safetensors (this may take 10-30 seconds)...")
        let startTime = Date()
        
        // Use MLX.loadArrays(url:) to load safetensors
        let weights: [String: MLXArray]
        do {
            weights = try MLX.loadArrays(url: safetensorsPath)
        } catch {
            print("❌ [WeightLoader] MLX.loadArrays(url:) failed: \(error)")
            print("   Trying loadArrays(data:) as fallback...")
            
            // Fallback to Data version
            let fileData = try Data(contentsOf: safetensorsPath)
            weights = try MLX.loadArrays(data: fileData)
        }
        
        let loadTime = Date().timeIntervalSince(startTime)
        print("⏱️  [WeightLoader] Loaded \(weights.count) tensors in \(String(format: "%.1f", loadTime)) seconds")
        
        // Log sample tensor names
        let sampleNames = Array(weights.keys.sorted().prefix(10))
        print("📋 [WeightLoader] Sample tensor names: \(sampleNames.joined(separator: ", "))")
        
        return (config, weights)
    }
}

