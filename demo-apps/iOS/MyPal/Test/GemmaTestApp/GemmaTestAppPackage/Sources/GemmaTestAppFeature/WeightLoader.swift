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
    /// Returns: ([String: Any] config dict, [String: MLXArray] weights)
    static func loadFromDirectory(_ dir: String) throws -> ([String: Any], [String: MLXArray]) {
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
        
        // 2) Load model.safetensors (single-file or split layout)
        let safetensorsPath = dirURL.appendingPathComponent("model.safetensors")
        let hasSingleFile = FileManager.default.fileExists(atPath: safetensorsPath.path)
        
        // Check for split files (model-00001-of-XXXXX.safetensors pattern)
        let contents = try FileManager.default.contentsOfDirectory(atPath: dir)
        let splitFiles = contents.filter { $0.hasPrefix("model-") && $0.hasSuffix(".safetensors") }.sorted()
        
        print("⚖️  [WeightLoader] Loading model weights...")
        let startTime = Date()
        
        var weights: [String: MLXArray] = [:]
        
        if hasSingleFile {
            // Single file
            print("   Found single model.safetensors file")
            do {
                weights = try MLX.loadArrays(url: safetensorsPath)
            } catch {
                print("❌ [WeightLoader] MLX.loadArrays(url:) failed: \(error)")
                print("   Trying loadArrays(data:) as fallback...")
                let fileData = try Data(contentsOf: safetensorsPath)
                weights = try MLX.loadArrays(data: fileData)
            }
        } else if !splitFiles.isEmpty {
            // Split files
            print("   Found \(splitFiles.count) split files: \(splitFiles.joined(separator: ", "))")
            for splitFile in splitFiles {
                let splitPath = dirURL.appendingPathComponent(splitFile)
                print("   Loading \(splitFile)...")
                do {
                    let splitWeights = try MLX.loadArrays(url: splitPath)
                    weights.merge(splitWeights) { (_, new) in new }
                } catch {
                    print("❌ [WeightLoader] Failed to load \(splitFile): \(error)")
                    throw error
                }
            }
        } else {
            throw NSError(
                domain: "WeightLoader",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "No model.safetensors or split files found at \(dir)"]
            )
        }
        
        let loadTime = Date().timeIntervalSince(startTime)
        print("⏱️  [WeightLoader] Loaded \(weights.count) tensors in \(String(format: "%.1f", loadTime)) seconds")
        
        // Log sample tensor names
        let sampleNames = Array(weights.keys.sorted().prefix(10))
        print("📋 [WeightLoader] Sample tensor names: \(sampleNames.joined(separator: ", "))")
        
        return (configDict, weights)
    }
}

