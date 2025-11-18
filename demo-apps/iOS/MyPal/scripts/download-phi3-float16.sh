#!/bin/bash
#
# Download Phi-3 Mini Float16 (non-quantized) model from HuggingFace
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Model repository and target directory
REPO="microsoft/Phi-3-mini-4k-instruct"
MODEL_DIR="${PROJECT_ROOT}/App/Models/phi-3-mini-4k-instruct-float16"

echo "📥 Downloading Phi-3 Mini Float16 model..."
echo "   Repository: ${REPO}"
echo "   Target: ${MODEL_DIR}"
echo ""

# Check if huggingface-cli is installed
if ! command -v huggingface-cli &> /dev/null; then
    echo "❌ huggingface-cli not found"
    echo "   Install it with: pip3 install 'huggingface_hub[cli]'"
    exit 1
fi

# Create model directory
mkdir -p "$MODEL_DIR"

# Download function
download_file() {
    local file=$1
    echo "⬇️  Downloading ${file}..."
    
    if huggingface-cli download "$REPO" "$file" \
        --local-dir "$MODEL_DIR" \
        --local-dir-use-symlinks False 2>&1; then
        echo "   ✅ ${file} downloaded"
        return 0
    else
        echo "   ⚠️  ${file} not found or failed to download"
        return 1
    fi
}

# Download essential files
echo "📦 Downloading model files..."
echo ""

# Model weights (float16 safetensors)
download_file "model.safetensors" || {
    echo "❌ Failed to download model weights"
    echo "   Trying split safetensors..."
    download_file "model-00001-of-00002.safetensors" || exit 1
    download_file "model-00002-of-00002.safetensors" || exit 1
}

# Config files
download_file "config.json" || {
    echo "❌ config.json is required"
    exit 1
}

# Tokenizer files
download_file "tokenizer.model" || {
    echo "⚠️  tokenizer.model not found, trying alternatives..."
}

download_file "tokenizer.json" || {
    echo "⚠️  tokenizer.json not found"
}

download_file "tokenizer_config.json" || {
    echo "⚠️  tokenizer_config.json not found (optional)"
}

# Optional files
download_file "special_tokens_map.json" || echo "   (optional, skipped)"
download_file "generation_config.json" || echo "   (optional, skipped)"

echo ""
echo "✅ Phi-3 Mini Float16 model download complete!"
echo ""
echo "📊 Model info:"
echo "   Location: ${MODEL_DIR}"
echo "   Format: Float16 (non-quantized)"
echo "   Size: ~7-8 GB"
echo ""
echo "🧪 Test with:"
echo "   cd Test && ./run_gemma_test.sh -d ../App/Models/phi-3-mini-4k-instruct-float16 -p 'Hello' -n 20"

