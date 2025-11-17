#!/usr/bin/env swift

// Quick script to check what the tokenizer outputs
import Foundation

// Test decoding specific token IDs that appeared in the garbage output
let badTokenIds: [Int32] = [8, 2691, 32, 168, 89, 113, 4257]  // From your output

print("Testing token decoding:")
print("Token IDs: \(badTokenIds)")
print("")
print("This suggests tokenizer.json is being used instead of tokenizer.model")
print("Gemma-3 uses SentencePiece (tokenizer.model), not HuggingFace format (tokenizer.json)")
