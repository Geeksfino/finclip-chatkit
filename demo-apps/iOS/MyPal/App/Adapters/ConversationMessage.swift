//
//  ConversationMessage.swift
//  MyPal
//
//  Shared data structure for conversation history messages
//  Used by both LocalLLMConversationHistoryManager and LocalLLMModelManager
//

import Foundation

/// Represents a conversation message for history formatting
/// Used to pass conversation history between components
struct ConversationMessage {
  let role: String  // "user" or "assistant"
  let content: String
  let timestamp: Date
}

