# Tokenizer Solution for Gemma-3

## Problem Summary

1. **Gemma-3 uses SentencePiece** (`tokenizer.model`)
2. **swift-transformers loads `tokenizer.json` instead** when both files exist
3. **Result**: Token IDs decoded with wrong vocabulary = garbage output
4. **swift-sentencepiece package doesn't exist** on GitHub

## Final Solution Options

### Option A: Use MLX-Community Gemma Model (RECOMMENDED)

MLX-Community models are specifically prepared for MLX Swift:
```bash
# Download MLX-optimized Gemma model
huggingface-cli download mlx-community/gemma-3-270m-it-4bit \
  --local-dir ../App/Models/gemma-3-270m-it-4bit-mlx \
  --include "*.safetensors" "tokenizer.json" "config.json"
```

MLX models include compatible tokenizers.

### Option B: Create Native SentencePiece Bridge

Create a C++ bridge to Google's SentencePiece library:

1. Add SentencePiece as a system library dependency
2. Create Swift wrapper using C interop
3. Load `tokenizer.model` directly

This is the CORRECT solution but requires more work.

### Option C: Use Python Bridge (Quick Workaround)

Create a Python script that uses SentencePiece and call it from Swift:

```swift
func pythonEncode(_ text: String) -> [Int32] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
    process.arguments = ["encode_sentencepiece.py", text]
    // ... capture output
}
```

Fast to implement but adds Python dependency.

### Option D: Manual Token ID Remapping

Since both tokenizers exist, create a mapping table:
1. For each token ID from `tokenizer.json`
2. Find corresponding token in `tokenizer.model`
3. Create a translation dict

This is hacky and error-prone.

## Decision

For now, I recommend:
1. **Short term**: Remove `tokenizer.json` and see if swift-transformers falls back properly
2. **Long term**: Switch to MLX-Community model or create native SentencePiece bridge

## Implementation

See `TokenizerBridge.swift` for the attempted SentencePiece integration.

The tokenizer test will verify correct operation:
- Input: "Hello"
- Expected output after decode: Contains "hello"
- Current output: Garbage multilingual text

Once this test passes, text generation will work correctly.

