#!/bin/bash
#
# Download Phi-3 Mini Float16 (non-quantized) model using curl
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Model repository and target directory
REPO="microsoft/Phi-3-mini-4k-instruct"
BASE_URL="https://huggingface.co/${REPO}/resolve/main"
MODEL_DIR="${PROJECT_ROOT}/App/Models/phi-3-mini-4k-instruct-float16"

echo "📥 Downloading Phi-3 Mini Float16 model..."
echo "   Repository: ${REPO}"
echo "   Target: ${MODEL_DIR}"
echo ""

# Create model directory
mkdir -p "$MODEL_DIR"

# Download function
download_file() {
    local file=$1
    local url="${BASE_URL}/${file}"
    local output="${MODEL_DIR}/${file}"
    
    echo "⬇️  Downloading ${file}..."
    
    if curl -L --fail --progress-bar "${url}?download=true" -o "$output" 2>&1; then
        echo "   ✅ ${file} downloaded"
        return 0
    else
        echo "   ⚠️  ${file} failed to download"
        rm -f "$output"
        return 1
    fi
}

# Download essential files
echo "📦 Downloading model files..."
echo ""

# Config files (small, download first)
download_file "config.json" || {
    echo "❌ config.json is required"
    exit 1
}

# Tokenizer files
download_file "tokenizer.model" || {
    echo "⚠️  tokenizer.model not found"
}

download_file "tokenizer.json" || {
    echo "⚠️  tokenizer.json not found"
}

download_file "tokenizer_config.json" || {
    echo "⚠️  tokenizer_config.json not found (optional)"
}

# Model weights (this will take a while - ~7GB)
echo ""
echo "⚠️  WARNING: The model file is ~7GB and will take several minutes to download"
echo "   Press Ctrl+C to cancel, or wait..."
echo ""

download_file "model.safetensors" || {
    echo "❌ Single file not found, trying split files..."
    download_file "model-00001-of-00002.safetensors" || {
        echo "❌ Failed to download model weights"
        exit 1
    }
    download_file "model-00002-of-00002.safetensors" || {
        echo "❌ Failed to download second weight file"
        exit 1
    }
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
du -sh "$MODEL_DIR" 2>/dev/null && echo ""
echo "🧪 Test with:"
echo "   cd Test && ./run_gemma_test.sh -d ../App/Models/phi-3-mini-4k-instruct-float16 -p 'Hello' -n 20"

