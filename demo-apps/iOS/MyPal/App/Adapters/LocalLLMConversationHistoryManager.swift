//
//  LocalLLMConversationHistoryManager.swift
//  MyPal
//
//  Manages conversation history retrieval and formatting for local LLM
//  Retrieves messages from CoreData and formats them for inclusion in prompts
//

import Foundation
import FinClipChatKit

/// Manages conversation history retrieval and formatting for local LLM
/// Uses ChatKit's higher-level API (ChatKitCoordinator) instead of NeuronKit directly
class LocalLLMConversationHistoryManager {
  private weak var coordinator: ChatKitCoordinator?
  
  init(coordinator: ChatKitCoordinator?) {
    self.coordinator = coordinator
  }
  
  /// Get conversation history for a given thread ID
  /// - Parameters:
  ///   - threadId: The conversation thread identifier (UUID string)
  ///   - maxTokens: Maximum tokens to include (for truncation)
  /// - Returns: 
  ///   - `nil`: Coordinator unavailable or query failed (temporary - may succeed later)
  ///   - `[]`: Coordinator available, query succeeded, but no history exists (permanent for this message)
  ///   - `[ConversationMessage]`: Successfully retrieved conversation history
  func getConversationHistory(threadId: String, maxTokens: Int) -> [ConversationMessage]? {
    guard let coordinator = coordinator else {
      print("⚠️ [HistoryManager] ChatKitCoordinator not available, cannot retrieve history")
      print("   This may be temporary - coordinator may become available later")
      return nil  // nil = couldn't query (coordinator unavailable)
    }
    
    // Convert threadId string to UUID
    guard let sessionId = UUID(uuidString: threadId) else {
      print("⚠️ [HistoryManager] Invalid threadId format: \(threadId)")
      return nil  // nil = couldn't query (invalid input)
    }
    
    do {
      // Fetch messages using ChatKit's runtime API (accessed through coordinator)
      // IMPORTANT: We use coordinator.runtime to ensure we're using the SAME runtime instance
      // that was initialized by the app (in SceneDelegate), not creating a new one
      // Use a large limit to get all messages, we'll truncate based on tokens
      let messages = try coordinator.runtime.messagesSnapshot(sessionId: sessionId, limit: 1000, before: nil)
      
      print("🔍 [HistoryManager] Raw messages from snapshot: \(messages.count) total messages")
      if !messages.isEmpty {
        print("   First message timestamp: \(messages.first?.timestamp ?? Date())")
        print("   Last message timestamp: \(messages.last?.timestamp ?? Date())")
      }
      
      // Convert NeuronMessage to ConversationMessage
      let conversationMessages = messages.compactMap { message -> ConversationMessage? in
        // Only include user and agent messages, skip system and tool messages
        let role: String
        switch message.sender {
        case .user:
          role = "user"
        case .agent:
          role = "assistant"
        case .system, .tool:
          // Skip system and tool messages for conversation history
          return nil
        }
        
        return ConversationMessage(
          role: role,
          content: message.content,
          timestamp: message.timestamp
        )
      }
      
      print("🔍 [HistoryManager] After filtering (user/agent only): \(conversationMessages.count) messages")
      
      // CRITICAL FIX: Ensure messages are in chronological order (oldest first)
      // messagesSnapshot may return messages in reverse chronological order (newest first)
      // We need chronological order for proper conversation flow
      let sortedMessages = conversationMessages.sorted { $0.timestamp < $1.timestamp }
      
      if sortedMessages.count != conversationMessages.count {
        print("⚠️ [HistoryManager] Messages were reordered (original count: \(conversationMessages.count), sorted count: \(sortedMessages.count))")
      }
      
      // Log message sequence for debugging
      if !sortedMessages.isEmpty {
        print("📋 [HistoryManager] Message sequence (chronological):")
        for (index, msg) in sortedMessages.enumerated() {
          let preview = msg.content.prefix(50).replacingOccurrences(of: "\n", with: " ")
          print("   [\(index)] \(msg.role): \(preview)...")
        }
      }
      
      // Truncate if necessary to fit within token limit
      // Note: truncateHistory expects chronological order and keeps most recent messages
      let truncated = truncateHistory(sortedMessages, maxTokens: maxTokens)
      
      if truncated.isEmpty {
        print("📚 [HistoryManager] Query succeeded but no conversation history found (first message in thread)")
        return []  // [] = successfully queried, but no history (permanent for this message)
      } else {
        print("📚 [HistoryManager] Retrieved \(sortedMessages.count) messages, using \(truncated.count) after truncation")
        print("📋 [HistoryManager] Final truncated history:")
        for (index, msg) in truncated.enumerated() {
          let preview = msg.content.prefix(50).replacingOccurrences(of: "\n", with: " ")
          print("   [\(index)] \(msg.role): \(preview)...")
        }
        return truncated  // [ConversationMessage] = successfully retrieved history
      }
      
    } catch {
      print("⚠️ [HistoryManager] Failed to retrieve conversation history: \(error)")
      print("   This may be temporary - query may succeed on retry")
      return nil  // nil = query failed (temporary - may succeed later)
    }
  }
  
  /// Format conversation history into a prompt-friendly string
  /// - Parameter messages: Array of conversation messages
  /// - Returns: Formatted string with conversation history
  func formatHistoryForPrompt(messages: [ConversationMessage]) -> String {
    guard !messages.isEmpty else {
      return ""
    }
    
    var formatted = ""
    for message in messages {
      // Format as "Role: content" for Gemma chat format
      let roleLabel = message.role == "user" ? "User" : "Assistant"
      formatted += "\(roleLabel): \(message.content)\n\n"
    }
    
    return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  /// Truncate conversation history to fit within token limit
  /// Keeps the most recent messages, removing oldest ones if necessary
  /// - Parameters:
  ///   - messages: Array of conversation messages in chronological order (oldest first)
  ///   - maxTokens: Maximum tokens allowed
  /// - Returns: Truncated array of messages in chronological order
  private func truncateHistory(_ messages: [ConversationMessage], maxTokens: Int) -> [ConversationMessage] {
    // Rough estimate: 1 token ≈ 4 characters
    // Add some buffer for formatting overhead
    // Ensure maxChars is never negative by bounding the buffer subtraction
    let bufferSize = min(500, maxTokens * 4 / 2)  // Use smaller of 500 or half of available chars
    let maxChars = max(0, (maxTokens * 4) - bufferSize)  // Ensure non-negative
    
    // If maxChars is 0 or very small, return empty array
    guard maxChars > 100 else {
      print("⚠️ [HistoryManager] Context window too small (\(maxTokens) tokens), skipping history")
      return []
    }
    
    print("🔍 [HistoryManager] Truncating history: \(messages.count) messages, maxChars: \(maxChars)")
    
    var totalChars = 0
    var truncated: [ConversationMessage] = []
    
    // Messages are already in chronological order (oldest first)
    // We want to keep the most recent messages, so we iterate from the end
    // This ensures we preserve the conversation flow while fitting within token limits
    for message in messages.reversed() {
      // Estimate characters for this message (role label + content + formatting)
      let messageChars = message.content.count + message.role.count + 10  // +10 for "User: " and "\n\n"
      
      if totalChars + messageChars <= maxChars {
        truncated.insert(message, at: 0)  // Insert at beginning to maintain chronological order
        totalChars += messageChars
        print("   ✓ Added \(message.role) message (\(messageChars) chars, total: \(totalChars)/\(maxChars))")
      } else {
        // Stop when we exceed the limit
        print("   ✗ Stopped at \(message.role) message (would exceed limit: \(totalChars + messageChars) > \(maxChars))")
        break
      }
    }
    
    if truncated.count < messages.count {
      print("⚠️ [HistoryManager] Truncated history from \(messages.count) to \(truncated.count) messages to fit token limit")
      print("   Removed \(messages.count - truncated.count) oldest message(s)")
    } else {
      print("✅ [HistoryManager] All \(truncated.count) messages fit within token limit")
    }
    
    return truncated
  }
}

