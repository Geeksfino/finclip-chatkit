//
//  ModelProtocol.swift
//  GemmaTestAppFeature
//
//  Protocol for supporting multiple LLM architectures (Gemma, Phi-3, etc.)
//

import Foundation
import MLX

/// Supported model types
public enum ModelType: String, CaseIterable {
    case gemma3_270m = "gemma-3-270m"
    case phi3_mini = "phi-3-mini"
    
    public var displayName: String {
        switch self {
        case .gemma3_270m: return "Gemma 3 270M"
        case .phi3_mini: return "Phi-3 Mini 3.8B"
        }
    }
}

/// Protocol for LLM models
public protocol LLMModel {
    /// Model type identifier
    var modelType: ModelType { get }
    
    /// Generate next token logits
    /// - Parameters:
    ///   - inputTokens: Input token IDs [batch, seq_len]
    ///   - cacheK: Key cache from previous generation
    ///   - cacheV: Value cache from previous generation
    /// - Returns: Tuple of (logits, updated cacheK, updated cacheV)
    func generateNextToken(
        _ inputTokens: MLXArray,
        cacheK: inout [[MLXArray?]],
        cacheV: inout [[MLXArray?]]
    ) throws -> (MLXArray, [[MLXArray?]], [[MLXArray?]])
    
    /// Forward pass through the model
    /// - Parameters:
    ///   - inputTokens: Input token IDs
    ///   - cacheK: Optional key cache
    ///   - cacheV: Optional value cache
    /// - Returns: Tuple of (output logits, updated caches)
    func forward(
        _ inputTokens: MLXArray,
        cacheK: [[MLXArray?]]?,
        cacheV: [[MLXArray?]]?
    ) throws -> (MLXArray, [[MLXArray?]]?, [[MLXArray?]]?)
}

/// Model configuration protocol
protocol ModelConfig {
    var vocabSize: Int { get }
    var hiddenSize: Int { get }
    var numLayers: Int { get }
    var numAttentionHeads: Int { get }
    var eosTokenId: Int { get }
    var bosTokenId: Int { get }
}

/// Model loader protocol
protocol ModelLoader {
    /// Load model from directory
    /// - Parameter directory: Path to model directory
    /// - Returns: Loaded model instance
    static func load(from directory: String) throws -> LLMModel
}

/// Model registry for multi-model support
@MainActor
final class ModelRegistry: @unchecked Sendable {
    static let shared = ModelRegistry()
    
    private var loaders: [ModelType: ModelLoader.Type] = [:]
    
    private init() {}
    
    /// Register a model loader
    func register(_ loader: ModelLoader.Type, for type: ModelType) {
        loaders[type] = loader
    }
    
    /// Detect model type from config
    func detectModelType(configPath: String) throws -> ModelType {
        let configURL = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: configURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let architectures = json?["architectures"] as? [String],
              let architecture = architectures.first else {
            throw ModelError.invalidConfig("No architecture specified")
        }
        
        // Detect based on architecture name
        if architecture.contains("Gemma") {
            return .gemma3_270m
        } else if architecture.contains("Phi3") || architecture.contains("Phi-3") {
            return .phi3_mini
        }
        
        throw ModelError.unsupportedArchitecture(architecture)
    }
    
    /// Load model automatically detecting type
    func loadModel(from directory: String) throws -> LLMModel {
        let configPath = (directory as NSString).appendingPathComponent("config.json")
        let modelType = try detectModelType(configPath: configPath)
        
        guard let loaderType = loaders[modelType] else {
            throw ModelError.noLoaderRegistered(modelType)
        }
        
        print("📦 [ModelRegistry] Detected model type: \(modelType.displayName)")
        return try loaderType.load(from: directory)
    }
}

/// Model errors
enum ModelError: Error, LocalizedError {
    case invalidConfig(String)
    case unsupportedArchitecture(String)
    case noLoaderRegistered(ModelType)
    case loadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfig(let msg):
            return "Invalid config: \(msg)"
        case .unsupportedArchitecture(let arch):
            return "Unsupported architecture: \(arch)"
        case .noLoaderRegistered(let type):
            return "No loader registered for: \(type.displayName)"
        case .loadFailed(let msg):
            return "Load failed: \(msg)"
        }
    }
}

