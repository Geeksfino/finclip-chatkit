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
  /// - Returns: Array of conversation messages in chronological order, or nil if unavailable
  func getConversationHistory(threadId: String, maxTokens: Int) -> [ConversationMessage]? {
    guard let coordinator = coordinator else {
      print("⚠️ [HistoryManager] ChatKitCoordinator not available, cannot retrieve history")
      return nil
    }
    
    // Convert threadId string to UUID
    guard let sessionId = UUID(uuidString: threadId) else {
      print("⚠️ [HistoryManager] Invalid threadId format: \(threadId)")
      return nil
    }
    
    do {
      // Fetch messages using ChatKit's runtime API (accessed through coordinator)
      // IMPORTANT: We use coordinator.runtime to ensure we're using the SAME runtime instance
      // that was initialized by the app (in SceneDelegate), not creating a new one
      // Use a large limit to get all messages, we'll truncate based on tokens
      let messages = try coordinator.runtime.messagesSnapshot(sessionId: sessionId, limit: 1000, before: nil)
      
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
      
      // Truncate if necessary to fit within token limit
      let truncated = truncateHistory(conversationMessages, maxTokens: maxTokens)
      
      print("📚 [HistoryManager] Retrieved \(conversationMessages.count) messages, using \(truncated.count) after truncation")
      return truncated
      
    } catch {
      print("⚠️ [HistoryManager] Failed to retrieve conversation history: \(error)")
      return nil
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
  ///   - messages: Array of conversation messages
  ///   - maxTokens: Maximum tokens allowed
  /// - Returns: Truncated array of messages
  private func truncateHistory(_ messages: [ConversationMessage], maxTokens: Int) -> [ConversationMessage] {
    // Rough estimate: 1 token ≈ 4 characters
    // Add some buffer for formatting overhead
    let maxChars = (maxTokens * 4) - 500  // Reserve 500 chars for current message and formatting
    
    var totalChars = 0
    var truncated: [ConversationMessage] = []
    
    // Iterate from most recent to oldest, keeping messages that fit
    for message in messages.reversed() {
      // Estimate characters for this message (role label + content + formatting)
      let messageChars = message.content.count + message.role.count + 10  // +10 for "User: " and "\n\n"
      
      if totalChars + messageChars <= maxChars {
        truncated.insert(message, at: 0)  // Insert at beginning to maintain chronological order
        totalChars += messageChars
      } else {
        // Stop when we exceed the limit
        break
      }
    }
    
    if truncated.count < messages.count {
      print("⚠️ [HistoryManager] Truncated history from \(messages.count) to \(truncated.count) messages to fit token limit")
    }
    
    return truncated
  }
}

