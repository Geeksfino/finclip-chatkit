//
//  AGUIFixtures.swift
//  MyChatGPT
//
//  Helper for loading AG-UI fixture events.
//

import Foundation

/// Helper for loading AG-UI fixture events from embedded data
enum AGUIFixtures {
  
  /// Represents an AG-UI protocol event with its JSON data
  struct Event {
    let data: Data
  }
  
  /// Generate echo response events with streaming prefix
  /// - Parameters:
  ///   - userInput: The user's message to echo back
  ///   - threadId: The conversation thread identifier
  ///   - runId: The currently active run identifier
  /// - Returns: Array of AG-UI events that stream a prefix followed by the user's input
  static func echoEvents(userInput: String, threadId: String, runId: String) throws -> [Event] {
    let messageId = UUID().uuidString
    let baseTimestamp = Int(Date().timeIntervalSince1970 * 1000)
    
    // Prefix deltas to demonstrate streaming effect
    let prefixDeltas = [
      "你好",
      "！我是一只数字鹦鹉，",
      "我只能模仿你说话。",
      "这是你的原话：\n\n"
    ]
    
    var eventDicts: [[String: Any]] = []
    
    // RUN_STARTED
    eventDicts.append([
      "type": "RUN_STARTED",
      "threadId": threadId,
      "runId": runId,
      "timestamp": baseTimestamp
    ])
    
    // TEXT_MESSAGE_START
    eventDicts.append([
      "type": "TEXT_MESSAGE_START",
      "messageId": messageId,
      "role": "assistant",
      "timestamp": baseTimestamp + 100
    ])
    
    // Prefix deltas (streaming effect)
    for (index, delta) in prefixDeltas.enumerated() {
      eventDicts.append([
        "type": "TEXT_MESSAGE_CONTENT",
        "messageId": messageId,
        "delta": delta,
        "timestamp": baseTimestamp + 200 + (index * 150)
      ])
    }
    
    // Echo user input (wrapped in bold markdown to demonstrate markdown rendering)
    eventDicts.append([
      "type": "TEXT_MESSAGE_CONTENT",
      "messageId": messageId,
      "delta": "**\(userInput)**",
      "timestamp": baseTimestamp + 200 + (prefixDeltas.count * 150)
    ])
    
    // TEXT_MESSAGE_END
    eventDicts.append([
      "type": "TEXT_MESSAGE_END",
      "messageId": messageId,
      "timestamp": baseTimestamp + 1000
    ])
    
    // RUN_FINISHED
    eventDicts.append([
      "type": "RUN_FINISHED",
      "threadId": threadId,
      "runId": runId,
      "timestamp": baseTimestamp + 1000
    ])
    
    return try eventDicts.map { dict -> Event in
      let eventData = try JSONSerialization.data(withJSONObject: dict)
      return Event(data: eventData)
    }
  }
  
  enum FixtureError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidFormat
    
    var errorDescription: String? {
      switch self {
      case .fileNotFound(let name):
        return "Fixture file '\(name).json' not found in bundle"
      case .invalidFormat:
        return "Fixture file is not in the expected JSON array format"
      }
    }
  }
}
