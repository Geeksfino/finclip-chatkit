# GemmaTest - Command-Line Testing for Gemma-3-270M

This directory contains a macOS app wrapper that allows testing the Gemma-3-270M model from the command line with full MLX Metal library support.

## Why a macOS App?

The original `swift run` approach failed because:
- MLX requires the Metal library (`default.metallib`) for GPU operations
- Swift Package executables don't bundle the Metal library
- A proper macOS app bundle includes all necessary Metal resources

## Building the App

```bash
cd GemmaTestApp
xcodebuild -workspace GemmaTestApp.xcworkspace -scheme GemmaTestApp -configuration Debug
```

Or use the MCP build tool from Warp.

## Running from Command Line

```bash
# Simple usage with defaults
./run_gemma_test.sh --prompt "Hello" --max-tokens 50

# With custom model path (absolute)
./run_gemma_test.sh --model-path /path/to/model --prompt "What is AI?" --max-tokens 100

# With temperature control
./run_gemma_test.sh --prompt "Hello" --max-tokens 50 --temperature 0.9
```

## Default Model Path

The app defaults to: `../App/Models/gemma-3-270m-it-4bit` (relative to the Test directory)

This resolves to: `/Users/cliang/repos/finclip/finclip-chatkit/demo-apps/iOS/MyPal/App/Models/gemma-3-270m-it-4bit`

## Current Status

✅ **Working:**
- MLX initialization and Metal library loading
- Model weight loading from safetensors
- Model architecture initialization
- GPU inference execution
- Command-line argument parsing
- Running from Test directory with relative paths

⚠️ **Known Issues:**
- **Tokenizer**: Currently uses a placeholder tokenizer that returns incorrect token IDs
  - This causes shape mismatch errors during inference: `Shapes (1,1,80) and (1,1,640) cannot be broadcast`
  - Token 1000 is returned for all inputs, which doesn't match the vocab
  - Need to integrate proper tokenizer (swift-transformers or SentencePiece)

## Command-Line Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--model-path` | `-d` | Path to model directory | `../App/Models/gemma-3-270m-it-4bit` |
| `--prompt` | `-p` | Input prompt text | `"Hello"` |
| `--max-tokens` | `-n` | Maximum tokens to generate | `50` |
| `--temperature` | `-T` | Sampling temperature | `0.7` |

## Architecture

```
GemmaTestApp/
├── GemmaTestApp/           # macOS app wrapper
│   └── GemmaTestAppApp.swift   # Command-line argument parsing & launch
├── GemmaTestAppPackage/    # Swift Package with Gemma implementation
│   └── Sources/
│       └── GemmaTestAppFeature/
│           ├── GemmaTestRunner.swift   # Main test runner
│           ├── Gemma3_270M.swift       # Model architecture
│           ├── GemmaConfig.swift       # Configuration
│           ├── WeightLoader.swift      # Load safetensors
│           ├── TokenizerBridge.swift   # Tokenizer (needs work)
│           └── Helpers.swift           # Sampling functions
└── Config/
    └── GemmaTestApp.entitlements   # Sandbox disabled for file access
```

## Next Steps

1. **Fix Tokenizer**: Integrate proper tokenizer library
   - Consider using swift-transformers
   - Or use SentencePiece directly via C++ bridge
2. **Test with correct tokens**: Once tokenizer works, verify full inference pipeline
3. **Performance optimization**: Profile and optimize if needed

## Technical Notes

- **No Sandbox**: App sandbox is disabled to allow file system access to model files
- **Metal Library**: Bundled in the app at `Contents/Resources/mlx-swift_Cmlx.bundle/Contents/Resources/default.metallib`
- **Current Directory**: The app uses `FileManager.default.currentDirectoryPath` to resolve relative paths
- **Exit Behavior**: App exits after test completes (code 0 for success, 1 for error)
