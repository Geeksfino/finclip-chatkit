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

/// Wrapper for SentencePiece tokenizer (CORRECT for Gemma-3)
class GemmaSentencePieceTokenizer: TokenizerProtocol {
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

/// Wrapper for swift-transformers Tokenizer (FALLBACK - uses wrong vocab for Gemma-3)
class SwiftTransformersTokenizer: TokenizerProtocol {
    private let tokenizer: Tokenizers.Tokenizer
    let eosTokenId: Int32
    let bosTokenId: Int32
    
    init(tokenizer: Tokenizers.Tokenizer, eosTokenId: Int32 = 1, bosTokenId: Int32 = 2) {
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
        print("⚠️  [SimpleTokenizer] Using placeholder decoding - results will be incorrect!")
        return "[Decoded: \(tokens.count) tokens]"
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
                    print("   This is the CORRECT tokenizer for Gemma-3")
                    return GemmaSentencePieceTokenizer(
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
        
        // PRIORITY 2: Warn if trying to use tokenizer.json
        if hasTokenizerJson && !hasTokenizerModel {
            print("❌ [TokenizerLoader] ERROR: Only tokenizer.json found")
            print("   Gemma-3 requires tokenizer.model (SentencePiece)")
            print("   Using tokenizer.json will produce GARBAGE OUTPUT")
            print("   Please re-download the model with tokenizer.model included")
        }
        
        // Fallback to placeholder
        print("⚠️  [TokenizerLoader] Using placeholder tokenizer")
        print("   ⚠️  WARNING: This will produce incorrect token encoding/decoding")
        print("   Please ensure tokenizer.model is available and swift-transformers supports it")
        return SimpleTokenizer(
            eosTokenId: Int32(config.eosTokenId),
            bosTokenId: Int32(config.bosTokenId)
        )
    }
}

