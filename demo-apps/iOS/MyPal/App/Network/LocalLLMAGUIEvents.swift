//
//  LocalLLMAGUIEvents.swift
//  MyPal
//
//  Helper for generating AG-UI protocol events from local LLM responses.
//  Similar to AGUIFixtures.echoEvents() but generates events from actual LLM output.
//

import Foundation

/// Helper for generating AG-UI protocol events from local LLM responses
enum LocalLLMAGUIEvents {
  
  /// Represents an AG-UI protocol event with its JSON data
  struct Event {
    let data: Data
  }
  
  /// Generate AG-UI events from LLM response text
  /// - Parameters:
  ///   - response: The LLM-generated response text
  ///   - threadId: The conversation thread identifier
  ///   - runId: The currently active run identifier
  ///   - contextItems: Attached ConvoUI context items (for reference, not included in response)
  ///   - selectedTools: Selected composer tools (for reference, not included in response)
  /// - Returns: Array of AG-UI events that stream the LLM response
  static func generateEventsFromLLM(
    response: String,
    threadId: String,
    runId: String,
    contextItems: [[String: Any]] = [],
    selectedTools: [[String: Any]] = []
  ) throws -> [Event] {
    let messageId = UUID().uuidString
    let baseTimestamp = Int(Date().timeIntervalSince1970 * 1000)
    
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
    
    // Split response into chunks for streaming effect
    // For now, we'll send the entire response as one chunk
    // In the future, this could be token-by-token streaming
    if !response.isEmpty {
      eventDicts.append([
        "type": "TEXT_MESSAGE_CONTENT",
        "messageId": messageId,
        "delta": response,
        "timestamp": baseTimestamp + 200
      ])
    }
    
    // TEXT_MESSAGE_END
    eventDicts.append([
      "type": "TEXT_MESSAGE_END",
      "messageId": messageId,
      "timestamp": baseTimestamp + 300
    ])
    
    // RUN_FINISHED
    eventDicts.append([
      "type": "RUN_FINISHED",
      "threadId": threadId,
      "runId": runId,
      "timestamp": baseTimestamp + 300
    ])
    
    return try eventDicts.map { dict -> Event in
      let eventData = try JSONSerialization.data(withJSONObject: dict)
      return Event(data: eventData)
    }
  }
  
  /// Generate AG-UI events from streaming LLM tokens
  /// - Parameters:
  ///   - tokens: Array of token strings from LLM
  ///   - threadId: The conversation thread identifier
  ///   - runId: The currently active run identifier
  ///   - completion: Completion handler called with events array
  static func streamEventsFromLLMTokens(
    tokens: [String],
    threadId: String,
    runId: String,
    completion: @escaping ([Event]) -> Void
  ) {
    let messageId = UUID().uuidString
    let baseTimestamp = Int(Date().timeIntervalSince1970 * 1000)
    
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
    
    // TEXT_MESSAGE_CONTENT for each token
    for (index, token) in tokens.enumerated() {
      eventDicts.append([
        "type": "TEXT_MESSAGE_CONTENT",
        "messageId": messageId,
        "delta": token,
        "timestamp": baseTimestamp + 200 + (index * 50)
      ])
    }
    
    // TEXT_MESSAGE_END
    eventDicts.append([
      "type": "TEXT_MESSAGE_END",
      "messageId": messageId,
      "timestamp": baseTimestamp + 200 + (tokens.count * 50)
    ])
    
    // RUN_FINISHED
    eventDicts.append([
      "type": "RUN_FINISHED",
      "threadId": threadId,
      "runId": runId,
      "timestamp": baseTimestamp + 200 + (tokens.count * 50)
    ])
    
    // Convert to events
    do {
      let events = try eventDicts.map { dict -> Event in
        let eventData = try JSONSerialization.data(withJSONObject: dict)
        return Event(data: eventData)
      }
      completion(events)
    } catch {
      print("❌ [LocalLLMAGUIEvents] Failed to generate events: \(error)")
      completion([])
    }
  }
}

