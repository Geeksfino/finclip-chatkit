# Model Download Scripts

This directory contains scripts for downloading LLM models for the MyPal iOS app.

## Available Models

### Gemma-3 270M MediaPipe (.task format)
- **Source**: Kaggle (MediaPipe-compatible format)
- **File**: `gemma-3-270m-it-int8.task`
- **Size**: ~150MB
- **Status**: ✅ Recommended for MediaPipe LLM Inference API
- **Use case**: Production-ready with Google MediaPipe
- **Download**: `make download-gemma-task` or `./scripts/download-gemma-task.sh`

### Gemma-3 270M (4-bit quantized, MLX format)
- **Repository**: `mlx-community/gemma-3-270m-it-4bit`
- **Size**: ~150MB
- **Status**: ⚠️ Deprecated (use MediaPipe .task format instead)
- **Use case**: Legacy MLX format (no longer used)

### Phi-3 Mini 4k Instruct (4-bit quantized)
- **Repository**: `mlx-community/Phi-3-mini-4k-instruct-4bit`
- **Size**: ~2.3GB
- **Status**: ✅ Recommended (officially supported by MLX)
- **Use case**: Production-ready, better quality than Gemma-3

## Usage

### Using Make (Recommended)

```bash
# Download Gemma-3 MediaPipe model (.task format) - RECOMMENDED
make download-gemma-task

# Download Gemma-3 MLX format (legacy)
make download-model

# Download Phi-3 only
make download-phi3

# Download all models (MLX format)
make download-all-models
```

### Using Scripts Directly

```bash
# Download Gemma-3 MediaPipe model (.task format) - RECOMMENDED
./scripts/download-gemma-task.sh

# Download Gemma-3 MLX format (legacy)
./scripts/download-model.sh

# Download Phi-3
./scripts/download-phi3-mini.sh
```

## Model Locations

Models are downloaded to:
- Gemma-3 MediaPipe (.task): `App/Models/gemma-3-270m-it-int8.task`
- Gemma-3 MLX format: `App/Models/gemma-3-270m-it-4bit/`
- Phi-3: `App/Models/phi-3-mini-4k-instruct-4bit/`

## Files Downloaded

Each model download includes:
- `model.safetensors` - Model weights (large file)
- `config.json` - Model configuration
- `tokenizer.model` - SentencePiece tokenizer (required)
- `tokenizer.json` - HuggingFace tokenizer (optional)
- `tokenizer_config.json` - Tokenizer configuration
- `added_tokens.json` - Additional tokens
- `special_tokens_map.json` - Special token mappings
- `chat_template.jinja` - Chat formatting template

## After Download

1. **Update Xcode project**:
   ```bash
   make generate
   ```

2. **Test the model**:
   ```bash
   cd Test
   ./run_gemma_test.sh -d ../App/Models/phi-3-mini-4k-instruct-4bit -p "Hello" -n 20
   ```

## Authentication

### Kaggle API (for MediaPipe .task models)

To download MediaPipe models from Kaggle, you need to set up Kaggle API credentials:

```bash
# Install Kaggle CLI
pip install kaggle

# Get API credentials
# 1. Go to https://www.kaggle.com/settings
# 2. Click "Create New API Token" to download kaggle.json
# 3. Place it at ~/.kaggle/kaggle.json
mkdir -p ~/.kaggle
mv ~/Downloads/kaggle.json ~/.kaggle/
chmod 600 ~/.kaggle/kaggle.json
```

The script will automatically use the credentials if present.

### HuggingFace Authentication (for MLX format models)

If you encounter rate limits, you can authenticate with HuggingFace:

```bash
# Install HuggingFace CLI
pip3 install --user "huggingface_hub[cli]"

# Login (creates token at ~/.cache/huggingface/token)
huggingface-cli login
```

The scripts will automatically use the token if present.

## Troubleshooting

### Download fails with 403/401
- Authenticate with HuggingFace (see above)
- Check if repository is public or requires access

### File size warnings
- Large files may take time to download
- Check your internet connection
- Verify repository URL is correct

### Script not executable
```bash
chmod +x scripts/download-model.sh
chmod +x scripts/download-phi3-mini.sh
```

## Adding New Models

To add a new model:

1. Copy `download-model.sh` to `download-<model-name>.sh`
2. Update `REPO` variable with HuggingFace repository
3. Update `MODEL_DIR` with target directory
4. Add Makefile target:
   ```makefile
   download-<model-name>:
       @./scripts/download-<model-name>.sh
   ```
5. Update `.PHONY` line in Makefile

