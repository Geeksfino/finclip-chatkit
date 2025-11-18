//
//  Phi3PromptBuilder.swift
//  GemmaTestAppFeature
//
//  Phi-3 chat template builder for formatting conversations
//

import Foundation

/// Builder for Phi-3 chat templates
public struct Phi3PromptBuilder {
    public let systemPrompt: String
    
    public init(systemPrompt: String = "You are a helpful AI assistant.") {
        self.systemPrompt = systemPrompt
    }
    
    /// Build a single-turn prompt
    /// - Parameter userMessage: The user's message
    /// - Returns: Formatted prompt in Phi-3 format
    public func buildPrompt(userMessage: String) -> String {
        return buildSingleTurn(system: systemPrompt, user: userMessage)
    }
    
    /// Build a single-turn prompt with custom system message
    /// - Parameters:
    ///   - system: System prompt
    ///   - user: User message
    /// - Returns: Formatted prompt
    private func buildSingleTurn(system: String, user: String) -> String {
        var prompt = ""
        
        // System message (with <|end|> token per official template)
        if !system.isEmpty {
            prompt += "<|system|>\n\(system)<|end|>\n"
        }
        
        // User message (with <|end|> token per official template)
        prompt += "<|user|>\n\(user)<|end|>\n"
        
        // Assistant start (for generation, no <|end|> yet)
        prompt += "<|assistant|>\n"
        
        return prompt
    }
    
    /// Build a multi-turn conversation
    /// - Parameter messages: Array of (role, content) tuples
    /// - Returns: Formatted prompt
    public func buildMultiTurn(messages: [(role: String, content: String)]) -> String {
        var prompt = ""
        
        // System message (if present)
        if !systemPrompt.isEmpty {
            prompt += "<|system|>\n\(systemPrompt)\n"
        }
        
        // Messages
        for message in messages {
            let role = message.role.lowercased()
            let content = message.content
            
            if role == "user" || role == "assistant" {
                prompt += "<|" + role + "|>\n\(content)\n"
            }
        }
        
        // End with assistant prefix for generation
        if messages.last?.role.lowercased() != "assistant" {
            prompt += "<|assistant|>\n"
        }
        
        return prompt
    }
}

/// Helper to add BOS token to prompt if needed
public func addBOSToken(_ prompt: String, bosTokenId: Int) -> String {
    // Phi-3 typically handles BOS automatically in tokenizer
    // But we can return as-is since tokenizer will add it
    return prompt
}

