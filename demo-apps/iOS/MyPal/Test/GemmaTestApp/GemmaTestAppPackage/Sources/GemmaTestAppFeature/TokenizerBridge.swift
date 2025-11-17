//
//  TokenizerBridge.swift
//  GemmaTest
//
//  Tokenizer bridge for Gemma models using SentencePiece
//  Uses tokenizer.model file (CORRECT for Gemma-3)
//

import Foundation
import Tokenizers
import SentencepieceTokenizer

/// Simple tokenizer interface
protocol TokenizerProtocol {
    func encode(_ text: String) throws -> [Int32]
    func decode(_ tokens: [Int32]) throws -> String
    var eosTokenId: Int32 { get }
    var bosTokenId: Int32 { get }
}

/// Wrapper for SentencePiece tokenizer (works for both Gemma-3 and Phi-3)
class SentencePieceTokenizerWrapper: TokenizerProtocol {
    private let tokenizer: SentencepieceTokenizer
    let eosTokenId: Int32
    let bosTokenId: Int32
    
    init(tokenizer: SentencepieceTokenizer, eosTokenId: Int32 = 1, bosTokenId: Int32 = 2) {
        self.tokenizer = tokenizer
        self.eosTokenId = eosTokenId
        self.bosTokenId = bosTokenId
    }
    
    func encode(_ text: String) throws -> [Int32] {
        let tokens = try tokenizer.encode(text)
        return tokens.map { Int32($0) }
    }
    
    func decode(_ tokens: [Int32]) throws -> String {
        let intTokens = tokens.map { Int($0) }
        return try tokenizer.decode(intTokens)
    }
}

/// Wrapper for swift-transformers Tokenizer (for Phi-3 tokenizer.json)
class SwiftTransformersTokenizer: TokenizerProtocol {
    private let tokenizer: Tokenizers.Tokenizer
    let eosTokenId: Int32
    let bosTokenId: Int32
    
    init(tokenizer: Tokenizers.Tokenizer, eosTokenId: Int32 = 32000, bosTokenId: Int32 = 1) {
        self.tokenizer = tokenizer
        self.eosTokenId = eosTokenId
        self.bosTokenId = bosTokenId
    }
    
    func encode(_ text: String) throws -> [Int32] {
        let tokens = tokenizer.encode(text: text)
        return tokens.map { Int32($0) }
    }
    
    func decode(_ tokens: [Int32]) throws -> String {
        let intTokens = tokens.map { Int($0) }
        return tokenizer.decode(tokens: intTokens)
    }
}

/// Placeholder tokenizer for basic testing (fallback)
class SimpleTokenizer: TokenizerProtocol {
    let eosTokenId: Int32
    let bosTokenId: Int32
    
    init(eosTokenId: Int32 = 1, bosTokenId: Int32 = 2) {
        self.eosTokenId = eosTokenId
        self.bosTokenId = bosTokenId
    }
    
    func encode(_ text: String) throws -> [Int32] {
        print("⚠️  [SimpleTokenizer] Using placeholder encoding - results will be incorrect!")
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.enumerated().map { Int32($0.offset + 1000) }
    }
    
    func decode(_ tokens: [Int32]) throws -> String {
        // Create a simple placeholder that generates readable text based on token IDs
        // This gives realistic-looking output while we work on proper tokenizer support
        var result = ""
        for token in tokens {
            let tokenID = Int(token)
            // Map token IDs to word-like tokens for display
            let pseudoWords = ["the", "and", "is", "in", "to", "a", "of", "for", "that", "with",
                              "this", "be", "will", "not", "have", "can", "on", "at", "from", "by",
                              "as", "or", "an", "are", "being", "about", "could", "do", "does", "get",
                              "had", "has", "he", "how", "if", "it", "me", "my", "no", "now",
                              "one", "our", "out", "s", "she", "so", "some", "than", "that", "the"]
            let pseudoWord = pseudoWords[tokenID % pseudoWords.count]
            if result.isEmpty {
                result = pseudoWord.prefix(1).uppercased() + pseudoWord.dropFirst()
            } else {
                result += " " + pseudoWord
            }
        }
        return result.isEmpty ? "[empty]" : result
    }
}

/// Tokenizer loader
struct TokenizerLoader {
    /// Load tokenizer from model directory using swift-transformers
    /// CRITICAL: Gemma-3 uses SentencePiece (tokenizer.model), not HuggingFace format (tokenizer.json)
    /// Loading tokenizer.json will cause garbage output due to vocabulary mismatch
    static func load(from dir: String, config: GemmaConfig) async throws -> TokenizerProtocol {
        let dirURL = URL(fileURLWithPath: dir)
        
        // Check for tokenizer files
        let tokenizerJsonPath = dirURL.appendingPathComponent("tokenizer.json")
        let tokenizerModelPath = dirURL.appendingPathComponent("tokenizer.model")
        let tokenizerConfigPath = dirURL.appendingPathComponent("tokenizer_config.json")
        
        let hasTokenizerJson = FileManager.default.fileExists(atPath: tokenizerJsonPath.path)
        let hasTokenizerModel = FileManager.default.fileExists(atPath: tokenizerModelPath.path)
        let hasTokenizerConfig = FileManager.default.fileExists(atPath: tokenizerConfigPath.path)
        
        print("📝 [TokenizerLoader] Found tokenizer files:")
        print("   tokenizer.model (SentencePiece): \(hasTokenizerModel)")
        print("   tokenizer.json (HuggingFace): \(hasTokenizerJson)")
        print("   tokenizer_config.json: \(hasTokenizerConfig)")
        
        // PRIORITY 1: Load SentencePiece tokenizer.model directly (CORRECT for Gemma-3)
        if hasTokenizerModel {
            do {
                print("📝 [TokenizerLoader] Loading SentencePiece tokenizer.model...")
                
                // Check tokenizer class
                if hasTokenizerConfig {
                    if let configData = try? Data(contentsOf: tokenizerConfigPath),
                       let configJson = try? JSONSerialization.jsonObject(with: configData) as? [String: Any],
                       let tokenizerClass = configJson["tokenizer_class"] as? String {
                        print("   Tokenizer class from config: \(tokenizerClass)")
                    }
                }
                
                // Load SentencePiece model directly using jkrukowski/swift-sentencepiece
                let tokenizer = try SentencepieceTokenizer(modelPath: tokenizerModelPath.path)
                
                // Verify the tokenizer works correctly
                // Test encode/decode with a simple string
                let testText = "Hello"
                let testTokens = try tokenizer.encode(testText)
                let decoded = try tokenizer.decode(testTokens)
                
                print("   Test encode/decode:")
                print("     Input: '\(testText)'")
                print("     Tokens: \(testTokens)")
                print("     Decoded: '\(decoded)'")
                
                if decoded.lowercased().contains("hello") {
                    print("✅ [TokenizerLoader] SentencePiece tokenizer loaded successfully!")
                    print("   Using CORRECT SentencePiece tokenizer for real output")
                    return SentencePieceTokenizerWrapper(
                        tokenizer: tokenizer,
                        eosTokenId: Int32(config.eosTokenId),
                        bosTokenId: Int32(config.bosTokenId)
                    )
                } else {
                    print("⚠️  [TokenizerLoader] SentencePiece test failed")
                    print("   Expected: '\(testText)', Got: '\(decoded)'")
                }
            } catch {
                print("⚠️  [TokenizerLoader] Failed to load SentencePiece tokenizer: \(error)")
                print("   Falling back to swift-transformers (will use wrong vocabulary)")
            }
        }
        
        // PRIORITY 2: Try to load tokenizer.json with swift-transformers (Phi-3 format)
        // Note: Full tokenizer.json support coming soon
        if hasTokenizerJson {
            print("📝 [TokenizerLoader] Found tokenizer.json - full support coming soon")
        }
        
        // Fallback to placeholder
        print("⚠️  [TokenizerLoader] Using placeholder tokenizer")
        print("   ⚠️  WARNING: This will produce placeholder text (not real model output)")
        return SimpleTokenizer(
            eosTokenId: Int32(config.eosTokenId),
            bosTokenId: Int32(config.bosTokenId)
        )
    }
}

