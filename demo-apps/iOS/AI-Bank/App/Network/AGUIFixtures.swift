//
//  AGUIFixtures.swift
//  MyChatGPT
//
//  Helper for loading AG-UI fixture events.
//

import Foundation

/// Helper for loading AG-UI fixture events from embedded data
enum AGUIFixtures {
  
  /// Attempt to decode payload (base64 or plain JSON string) into JSON object
  private static func decodePayloadJSONObject(_ payload: String) -> [String: Any]? {
    // Try base64 first (ignore invalid characters/padding)
    if let data = Data(base64Encoded: payload, options: [.ignoreUnknownCharacters]),
       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      return obj
    }

    // Fall back to interpreting the payload as raw JSON string
    if let data = payload.data(using: .utf8),
       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      return obj
    }

    return nil
  }

  private static func string(from value: Any?) -> String? {
    switch value {
    case let number as NSNumber:
      // Handle booleans separately to avoid 0/1 output
      if CFGetTypeID(number) == CFBooleanGetTypeID() {
        return (number.boolValue ? "true" : "false")
      }
      return number.stringValue
    case let str as String:
      return str
    default:
      return nil
    }
  }

  private static func double(from value: Any?) -> Double? {
    if let number = value as? NSNumber { return number.doubleValue }
    if let str = value as? String { return Double(str) }
    return nil
  }

  private static func truncated(_ text: String, limit: Int = 120) -> String {
    guard text.count > limit else { return text }
    return text.prefix(limit) + "…"
  }

  /// Format a context type string (e.g., "calendar_event") as a display name ("Calendar Event")
  private static func displayName(forType type: String) -> String {
    return type
      .replacingOccurrences(of: "_", with: " ")
      .capitalized
  }

  /// Render a human-readable summary for a single context item
  private static func prettySummary(for item: [String: Any]) -> String {
    let type = (item["contextType"] as? String) ?? "unknown"
    let name = (item["displayName"] as? String) ?? displayName(forType: type)
    let encoded = (item["encodedContent"] as? String) ?? ""
    let metadata = (item["metadata"] as? [String: Any]) ?? [:]
    let legacyMeta = (item["encodingMetadata"] as? [String: Any]) ?? [:]
    let mergedMeta = legacyMeta.merging(metadata) { _, new in new }
    let mime = (mergedMeta["mime"] as? String) ?? (mergedMeta["contentType"] as? String) ?? ""

    // Default fallback when we cannot decode
    let fallback = encoded.isEmpty ? "(no content)" : truncated(encoded)

    // Prefer provider-generated localized description when available
    if let localized = mergedMeta["localizedDescription"] as? String, !localized.isEmpty {
      let icon: String
      switch type {
      case "location": icon = "📍"
      case "calendar", "calendar_event", "event": icon = "🗓️"
      default: icon = "🔗"
      }
      return "\(icon) \(name): \(localized)"
    }

    // Prefer pretty formatting for known types
    switch type {
    case "location":
      if let obj = decodePayloadJSONObject(encoded) {
        var lat = double(from: obj["latitude"]) ?? double(from: obj["lat"])
        var lon = double(from: obj["longitude"]) ?? double(from: obj["lng"]) ?? double(from: obj["lon"])
        // Nested coordinates (common in CoreLocation exports)
        if let coords = obj["coordinates"] as? [String: Any] {
          lat = lat ?? double(from: coords["latitude"]) ?? double(from: coords["lat"])
          lon = lon ?? double(from: coords["longitude"]) ?? double(from: coords["lng"]) ?? double(from: coords["lon"])
        }
        let place = string(from: obj["name"]) ?? string(from: obj["label"]) ?? string(from: obj["title"]) ?? name
        let accuracy = double(from: obj["horizontalAccuracy"]) ?? double(from: obj["accuracy"])

        var parts: [String] = []
        if let lat = lat { parts.append(String(format: "lat=%.5f", lat)) }
        if let lon = lon { parts.append(String(format: "lon=%.5f", lon)) }
        if let accuracy = accuracy { parts.append(String(format: "±%.0fm", accuracy)) }
        if !place.isEmpty { parts.append("name=\(place)") }
        if !parts.isEmpty { return "📍 \(name): " + parts.joined(separator: ", ") }

        // As a fallback, pretty print the JSON for inspection
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]),
           let pretty = String(data: data, encoding: .utf8) {
          return "📍 \(name):\n" + pretty
        }
      }
      return "📍 \(name): \(fallback)"

    case "calendar", "calendarEvent", "event":
      if let obj = decodePayloadJSONObject(encoded) {
        let title = obj["title"] ?? obj["summary"] ?? name
        let start = obj["start"] ?? obj["startDate"]
        let end = obj["end"] ?? obj["endDate"]
        let loc = obj["location"]
        var lines: [String] = ["🗓️ \(title)"]
        if let start = start { lines.append("  start: \(start)") }
        if let end = end { lines.append("  end:   \(end)") }
        if let loc = loc { lines.append("  where: \(loc)") }
        return lines.joined(separator: "\n")
      }
      if mime.contains("json"), let obj = decodePayloadJSONObject(encoded) {
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]),
           let pretty = String(data: data, encoding: .utf8) {
          return "🗓️ \(name):\n" + pretty
        }
      }
      return "🗓️ \(name): \(fallback)"

    default:
      // If mime suggests JSON, try to pretty print any item type
      if mime.contains("json"), let obj = decodePayloadJSONObject(encoded) {
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]),
           let pretty = String(data: data, encoding: .utf8) {
          return "🔗 \(name):\n" + pretty
        }
      }
      return "🔗 \(name): \(fallback)"
    }
  }
  
  /// Represents an AG-UI protocol event with its JSON data
  struct Event {
    let data: Data
  }
  
  /// Generate echo response events with streaming prefix
  /// - Parameters:
  ///   - userInput: The user's message to echo back
  ///   - threadId: The conversation thread identifier
  ///   - runId: The currently active run identifier
  ///   - contextItems: Attached ConvoUI context items to echo back
  /// - Returns: Array of AG-UI events that stream a prefix followed by the user's input and context summary
  static func echoEvents(userInput: String, threadId: String, runId: String, contextItems: [[String: Any]] = []) throws -> [Event] {
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
    
    // Add context summary if any items were attached
    if !contextItems.isEmpty {
      let contextLines = contextItems.map { prettySummary(for: $0) }
      let contextText = "\n\n**Attached Context:**\n" + contextLines.joined(separator: "\n")
      eventDicts.append([
        "type": "TEXT_MESSAGE_CONTENT",
        "messageId": messageId,
        "delta": contextText,
        "timestamp": baseTimestamp + 200 + (prefixDeltas.count * 150) + 100
      ])
    }
    
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
