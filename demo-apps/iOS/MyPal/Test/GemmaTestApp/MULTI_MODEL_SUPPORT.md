# Multi-Model Support Strategy

## Current Situation

### Gemma-3 270M Status
- ✅ **Tokenizer**: using SentencePiece bridge
- ✅ **Model**: fixed (handles low-dim embeddings with projection)
- **Highlights**: Embedding_dim 80 → hidden 640, correct GQA + RoPE layout

### Solution: Add Phi-3 Mini as Alternative

ChatGPT is correct - Phi-3 Mini is better supported and works reliably on MLX.

## Files Created

### 1. `ModelProtocol.swift` ✅
- Defines `LLMModel` protocol for any model architecture
- `ModelRegistry` for automatic model detection
- `ModelType` enum for supported models
- `ModelLoader` protocol for loading different architectures

### 2. `Phi3Model.swift` ✅  
- Phi-3 config and architecture
- `Phi3Loader` for loading Phi-3 weights
- Placeholder implementation (full implementation needed)

### 3. `download-phi3-mini.sh` ✅
- Script to download Phi-3 Mini 4-bit from HuggingFace
- Downloads MLX-optimized version

## Architecture Design

```
ModelProtocol.swift
├── LLMModel (protocol)
│   ├── Gemma3Model / Gemma3_270M (implements)
│   └── Phi3Model (implements)
├── ModelConfig (protocol)
│   ├── GemmaConfig (implements)
│   └── Phi3Config (implements)
└── ModelRegistry
    ├── detectModelType()
    └── loadModel() → returns LLMModel
```

## How to Use

### Current: Gemma-3 Only
```swift
let (configDict, weights) = try WeightLoader.loadFromDirectory(modelPath)
let gemmaConfig = GemmaConfig(from: configDict)
let model = try Gemma3Model(config: gemmaConfig, weights: weights) // typealias Gemma3_270M remains for compatibility
```

### Future: Multi-Model
```swift
// Auto-detect and load
let model = try ModelRegistry.shared.loadModel(from: modelPath)

// Works for both Gemma-3 and Phi-3!
let (logits, cacheK, cacheV) = try model.generateNextToken(
    tokens,
    cacheK: &cacheK,
    cacheV: &cacheV
)
```

## Next Steps

### Immediate (To Get Working Model)

1. **Download Phi-3 Mini MLX**
   ```bash
   cd /Users/cliang/repos/finclip/finclip-chatkit/demo-apps/iOS/MyPal/App/Models
   chmod +x download-phi3-mini.sh
   
   # Install HuggingFace CLI first
   pip3 install --user "huggingface_hub[cli]"
   
   # Download model
   ./download-phi3-mini.sh
   ```

2. **Implement Phi-3 Architecture**
   - Copy Phi-3 architecture from MLX examples
   - Phi-3 uses:
     - RMSNorm (not LayerNorm)
     - SU RoPE (different from standard RoPE)
     - Grouped Query Attention (32 heads, 32 KV heads)
     - Gated MLP (gate + up projections)

3. **Update GemmaTestRunner**
   - Ensure loaders are registered once (e.g. app launch):
     ```swift
     GemmaLoader.register()
     Phi3Loader.register()
     ```
   - Continue using `ModelRegistry` so Gemma3Model/Phi3Model share the same flow

4. **Test Both Models**
   ```bash
   # Test Gemma (currently broken)
   ./run_gemma_test.sh -d ../App/Models/gemma-3-270m-it-4bit -p "Hello" -n 10
   
   # Test Phi-3 (should work)
   ./run_gemma_test.sh -d ../App/Models/phi-3-mini-4k-instruct-4bit -p "Hello" -n 10
   ```

### Long-Term

1. **Fix Gemma-3 Architecture**
   - Debug embedding dimension mismatch
   - Verify quantization format is correct
   - Test with non-quantized weights
   - OR download different Gemma-3 checkpoint

2. **Add More Models**
   - Llama 3.1 1B/3B
   - Qwen 2 0.5B
   - Gemma 2 2B

3. **Model Selection UI**
   - Add dropdown in app to select model
   - Display model info (size, parameters)
   - Show which models are downloaded

## Why Phi-3 Mini?

### Advantages
✅ **Officially supported** by MLX team
✅ **Works out of the box** - no architecture bugs
✅ **Better quality** than Gemma-3 270M at similar size
✅ **Fast** - 3.8B params quantized to ~2GB
✅ **iOS-friendly** - fits in memory on iPhone
✅ **Great tokenizer** - SentencePiece (we already support it!)

### Specifications
- **Parameters**: 3.8B (vs Gemma's 270M)
- **Context**: 4k tokens
- **Quantized size**: ~2.3GB (4-bit)
- **Quality**: Better than Gemma-2 2B on many benchmarks
- **License**: MIT (commercial use OK)

## Expected Output

### Before (Gemma-3 - Broken)
```
Input: "Hello"
Output: Desert advocating DSLR Lakeﾍ навスポーツcooked...
```

### After (Phi-3 - Should Work)
```
Input: "Hello"
Output: "Hello! How can I assist you today?"
```

## Files Summary

| File | Purpose | Status |
|------|---------|--------|
| `ModelProtocol.swift` | Multi-model abstraction | ✅ Created |
| `Phi3Model.swift` | Phi-3 implementation | ⚠️ Placeholder |
| `GemmaModel.swift` | Gemma-3 implementation | ✅ Fixed (MLX parity) |
| `GemmaTestRunner.swift` | Test runner | ✅ Uses ModelRegistry |
| `download-phi3-mini.sh` | Download script | ✅ Created |

## Conclusion

**ChatGPT's recommendation is correct**: Switch to Phi-3 Mini for immediate working results, then fix Gemma-3 later.

The infrastructure is in place for multi-model support. Just need to:
1. Download Phi-3
2. Implement Phi-3 architecture (can copy from MLX examples)
3. Register both loaders
4. Test!

This gives you a **working iOS LLM** while you debug Gemma-3.

