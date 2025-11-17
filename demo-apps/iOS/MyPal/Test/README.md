# Gemma-3-270M Test Program

Command-line macOS program for testing Gemma-3-270M model loading and inference.

## Requirements

- macOS 13.0 or later
- Swift 5.9 or later
- MLX-Swift package (automatically downloaded)
- Gemma-3-270M model files (from mlx-community on HuggingFace)

## Setup

1. Ensure you have the model files downloaded to `../App/Models/gemma-3-270m-it-4bit/`:
   - `config.json`
   - `model.safetensors`
   - `tokenizer.json` (optional)
   - `tokenizer.model` (optional)

2. Build the test program:
   ```bash
   cd Test
   swift build
   ```

## Usage

Run the test program with:

```bash
swift run GemmaTest --model-path ../App/Models/gemma-3-270m-it-4bit --prompt "Hello, how are you?" --max-tokens 50
```

### Options

- `--model-path` (required): Path to the model directory containing `config.json` and `model.safetensors`
- `--prompt` (optional, default: "Hello"): Input text prompt
- `--max-tokens` (optional, default: 50): Maximum number of tokens to generate
- `--temperature` (optional, default: 0.7): Sampling temperature (0.0 = greedy, higher = more random)
- `--top-k` (optional, default: 50): Top-k sampling parameter

### Examples

```bash
# Basic test
swift run GemmaTest --model-path ../App/Models/gemma-3-270m-it-4bit

# Custom prompt
swift run GemmaTest --model-path ../App/Models/gemma-3-270m-it-4bit --prompt "What is machine learning?" --max-tokens 100

# Greedy sampling (deterministic)
swift run GemmaTest --model-path ../App/Models/gemma-3-270m-it-4bit --prompt "Hello" --temperature 0.0
```

## Architecture

The test program implements a corrected Gemma-3-270M model with:

- ✅ Correct LayerNorm signature (`normalizedShape` parameter)
- ✅ Proper GQA (Grouped Query Attention) with 16 Q heads and 4 KV heads
- ✅ Full RoPE (Rotary Positional Embeddings) implementation
- ✅ Working KV cache for autoregressive generation
- ✅ No dimension slicing hacks
- ✅ Correct weight handling (no incorrect transposes)

## Files

- `main.swift`: Command-line entry point
- `WeightLoader.swift`: Loads config.json and model.safetensors
- `Gemma3_270M.swift`: Complete corrected model implementation
- `GemmaConfig.swift`: Model configuration struct
- `TokenizerBridge.swift`: Tokenizer interface (placeholder for now)
- `Helpers.swift`: Utility functions (GELU, SiLU, sampling)

## Notes

- The tokenizer is currently a placeholder. For production use, integrate with `swift-transformers` or MLX's tokenizer.
- Model loading may take 10-30 seconds for the first run.
- Generation speed depends on your Mac's hardware (Apple Silicon recommended).

## Troubleshooting

### Model not found
Ensure the model path is correct and contains `config.json` and `model.safetensors`.

### Dimension errors
Check that you're using the correct model (Gemma-3-270M 4-bit from mlx-community). The architecture constants are hardcoded for this specific model.

### Slow generation
This is expected for CPU-only execution. Apple Silicon Macs will use GPU acceleration automatically via MLX.

