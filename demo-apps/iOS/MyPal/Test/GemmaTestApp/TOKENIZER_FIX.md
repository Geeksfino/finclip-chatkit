# Tokenizer Fix for Gemma-3

## Problem

Gemma-3 uses **SentencePiece** (tokenizer.model), but swift-transformers' `AutoTokenizer` is loading **tokenizer.json** instead, causing garbage output.

## Root Cause

When both `tokenizer.json` and `tokenizer.model` exist in the directory:
- `AutoTokenizer.from(modelFolder:)` prefers `tokenizer.json` (HuggingFace format)
- This uses the WRONG vocabulary for Gemma-3
- Result: Correct token IDs get decoded with wrong vocabulary = garbage multilingual text

## Solution Options

### Option 1: Remove tokenizer.json (RECOMMENDED)
```bash
cd ../App/Models/gemma-3-270m-it-4bit
mv tokenizer.json tokenizer.json.backup
```

Then swift-transformers will be FORCED to use `tokenizer.model`.

### Option 2: Use LanguageModelConfigurationFromHub explicitly
```swift
let configuration = LanguageModelConfigurationFromHub(
    modelFolder: modelURL,
    hubApi: .init()
)
// Force it to load tokenizer.model
```

### Option 3: Load SentencePiece directly
Add a Swift SentencePiece wrapper and load tokenizer.model directly, bypassing AutoTokenizer.

## Testing the Fix

After applying the fix, test with:
```bash
./run_gemma_test.sh -p "Hello" -n 10
```

Expected output should be normal English text, not garbage like:
```
visibleXamarin बंद gelin strنين DEM...
```

## Verification

The tokenizer test in TokenizerBridge.swift will verify:
1. Encode "Hello" 
2. Decode the tokens
3. Check if decoded text contains "hello"

If this test passes, the tokenizer is correct.

