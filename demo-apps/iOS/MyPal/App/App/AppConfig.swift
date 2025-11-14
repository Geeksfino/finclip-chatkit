//
//  AppConfig.swift
//  MyPal
//
//  Application-specific configuration constants
//

import Foundation

enum ConnectionMode {
  case remote
  case local
}

struct AppConfig {
  /// Current connection mode (remote server or local LLM)
  static var currentMode: ConnectionMode = .remote
  
  /// Default agent ID for conversations
  static let defaultAgentId = UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!
  
  /// Default server URL for the agent endpoint
  static let defaultServerURL = URL(string: "http://127.0.0.1:3000/agent")!
  
  /// Default agent name for persistence
  static let defaultAgentName = "My Agent"
  
  /// Default user ID
  static let defaultUserId = "demo-user"
  
  // MARK: - Local LLM Configuration (Gemma 270M)
  
  /// Model name for local LLM
  static let localModelName = "gemma-270m"
  
  /// Hugging Face repository for Gemma 270M MLX model
  /// Using mlx-community version (pre-converted for MLX, should work with MLX.loadArrays)
  /// Options: gemma-3-270m-it-4bit (smaller, ~200MB), gemma-3-270m-it-8bit (better quality, ~400MB), gemma-3-270m-it-bf16 (full precision, ~500MB)
  static let localModelRepository = "mlx-community/gemma-3-270m-it-4bit"
  
  /// Model file name (without extension)
  static let localModelFileName = "gemma-3-270m-it-4bit"
  
  /// Context window size for local LLM
  static let localModelContextSize = 2048
  
  /// Temperature for local LLM inference
  static let localModelTemperature: Float = 0.7
  
  /// Use bundled model if available (for development/testing)
  /// Set to false to always download on-demand
  static let preferBundledModel = true
}

