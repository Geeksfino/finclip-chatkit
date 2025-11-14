#!/bin/bash
# Alternative: Download using Hugging Face CLI (recommended if repository requires auth)
# Install: pip install huggingface-hub
# Note: Newer versions use 'hf' command instead of 'huggingface-cli'

set -e

REPO="mlx-community/gemma-3-270m-it-4bit"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODEL_DIR="${PROJECT_ROOT}/App/Models/gemma-3-270m-it-4bit"

echo "📥 Downloading Gemma 270M model using Hugging Face CLI..."
echo "   Repository: ${REPO}"
echo "   Destination: ${MODEL_DIR}"

# Check if hf (new) or huggingface-cli (old) is installed
HF_CMD=""
if command -v hf &> /dev/null; then
    HF_CMD="hf"
elif command -v huggingface-cli &> /dev/null; then
    HF_CMD="huggingface-cli"
else
    echo "❌ Hugging Face CLI not found"
    echo ""
    echo "Install with:"
    echo "  pip install huggingface-hub"
    echo ""
    echo "Or use the curl-based script: scripts/download-model.sh"
    exit 1
fi

echo "✓ Using: ${HF_CMD}"

# Create model directory
mkdir -p "${MODEL_DIR}"

# Download files using hf/huggingface-cli
echo ""
echo "Downloading model files..."

# Download model weights file (may be large, ~150MB+)
# Try model.safetensors first (this is the standard name for MLX-community models)
echo "📥 Downloading model.safetensors..."
${HF_CMD} download "${REPO}" \
    "model.safetensors" \
    --local-dir "${MODEL_DIR}" \
    --local-dir-use-symlinks False || {
    echo "⚠️  model.safetensors not found, trying alternatives..."
    ${HF_CMD} download "${REPO}" \
        "weights.safetensors" \
        --local-dir "${MODEL_DIR}" \
        --local-dir-use-symlinks False || {
        echo "❌ Could not find weights file"
        exit 1
    }
}

# Download config.json
echo "📥 Downloading config.json..."
${HF_CMD} download "${REPO}" \
    "config.json" \
    --local-dir "${MODEL_DIR}" \
    --local-dir-use-symlinks False || {
    echo "⚠️  config.json not found, trying alternative..."
    ${HF_CMD} download "${REPO}" \
        "model_config.json" \
        --local-dir "${MODEL_DIR}" \
        --local-dir-use-symlinks False || {
        echo "❌ Could not find config file"
        exit 1
    }
}

# Download tokenizer files (required for proper tokenization)
echo "📥 Downloading tokenizer.json..."
${HF_CMD} download "${REPO}" \
    "tokenizer.json" \
    --local-dir "${MODEL_DIR}" \
    --local-dir-use-symlinks False || {
    echo "❌ tokenizer.json is required but not found"
    exit 1
}

# Download tokenizer_config.json (required for swift-transformers)
echo "📥 Downloading tokenizer_config.json..."
${HF_CMD} download "${REPO}" \
    "tokenizer_config.json" \
    --local-dir "${MODEL_DIR}" \
    --local-dir-use-symlinks False || {
    echo "⚠️  tokenizer_config.json not found (may cause tokenizer loading issues)"
}

# Download tokenizer.model (SentencePiece model file, required for some tokenizers)
echo "📥 Downloading tokenizer.model..."
${HF_CMD} download "${REPO}" \
    "tokenizer.model" \
    --local-dir "${MODEL_DIR}" \
    --local-dir-use-symlinks False || {
    echo "⚠️  tokenizer.model not found (may be required for some tokenizers)"
}

# Download additional tokenizer-related files
echo "📥 Downloading added_tokens.json..."
${HF_CMD} download "${REPO}" \
    "added_tokens.json" \
    --local-dir "${MODEL_DIR}" \
    --local-dir-use-symlinks False || {
    echo "ℹ️  added_tokens.json not found (optional)"
}

echo "📥 Downloading special_tokens_map.json..."
${HF_CMD} download "${REPO}" \
    "special_tokens_map.json" \
    --local-dir "${MODEL_DIR}" \
    --local-dir-use-symlinks False || {
    echo "ℹ️  special_tokens_map.json not found (optional)"
}

# Download chat template (useful for formatting conversations)
echo "📥 Downloading chat_template.jinja..."
${HF_CMD} download "${REPO}" \
    "chat_template.jinja" \
    --local-dir "${MODEL_DIR}" \
    --local-dir-use-symlinks False || {
    echo "ℹ️  chat_template.jinja not found (optional, but recommended)"
}

echo ""
echo "✅ Model download complete!"
echo "   Files are in: ${MODEL_DIR}"
echo ""
echo "📦 To bundle with the app:"
echo "   1. Run 'make generate' to update Xcode project"
echo "   2. Build the app - files will be included in bundle"

