//
//  AppConfig.swift
//  Simple
//
//  Application-specific configuration constants
//

import Foundation

struct AppConfig {
  /// Default agent ID for conversations
  static let defaultAgentId = UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!
  
  /// Default server URL for the agent endpoint
  static let defaultServerURL = URL(string: "http://127.0.0.1:3000/agent")!
  
  /// Default agent name for persistence
  static let defaultAgentName = "My Agent"
  
  /// Default user ID
  static let defaultUserId = "demo-user"
}

