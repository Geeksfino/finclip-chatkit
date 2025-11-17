#!/bin/bash
# Download Phi-3 Mini 4k Instruct model files for bundling with the app
# Run this script during development to bundle the model with the app

set -e

REPO="mlx-community/Phi-3-mini-4k-instruct-4bit"
# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODEL_DIR="${PROJECT_ROOT}/App/Models/phi-3-mini-4k-instruct-4bit"

# Try different Hugging Face URL formats
BASE_URL="https://huggingface.co/${REPO}/resolve/main"

echo "📥 Downloading Phi-3 Mini 4k Instruct model files..."
echo "   Repository: ${REPO}"
echo "   Destination: ${MODEL_DIR}"

# Create model directory
mkdir -p "${MODEL_DIR}"

# Get Hugging Face token
HF_TOKEN=""
if [ -f "${HOME}/.cache/huggingface/token" ]; then
    HF_TOKEN=$(cat "${HOME}/.cache/huggingface/token" 2>/dev/null | tr -d '\n')
fi

# Function to download a file
download_file() {
    local filename=$1
    local url="${BASE_URL}/${filename}"
    local dest="${MODEL_DIR}/${filename}"
    
    echo "📥 Downloading ${filename}..."
    echo "   URL: ${url}"
    
    local http_code=0
    if command -v curl &> /dev/null; then
        # Use curl with authentication header if token exists
        if [ -n "${HF_TOKEN}" ]; then
            http_code=$(curl -L -H "Authorization: Bearer ${HF_TOKEN}" -w "%{http_code}" -o "${dest}" "${url}" 2>/dev/null || echo "000")
        else
            http_code=$(curl -L -w "%{http_code}" -o "${dest}" "${url}" 2>/dev/null || echo "000")
        fi
    elif command -v wget &> /dev/null; then
        # Use wget with better error handling
        if wget -O "${dest}" "${url}" 2>&1 | grep -q "200 OK"; then
            http_code="200"
        else
            http_code="000"
        fi
    else
        echo "❌ Neither curl nor wget found. Please install one."
        return 1
    fi
    
    # Check HTTP response code
    if [ "${http_code}" != "200" ]; then
        echo "❌ Failed to download ${filename} (HTTP ${http_code})"
        rm -f "${dest}" 2>/dev/null
        return 1
    fi
    
    # Check file size and content
    local size=$(stat -f%z "${dest}" 2>/dev/null || stat -c%s "${dest}" 2>/dev/null || echo "0")
    
    # Check if file contains error message (too small or contains error text)
    if [ "${size}" -lt 100 ]; then
        if head -1 "${dest}" 2>/dev/null | grep -qi "error\|invalid\|not found"; then
            echo "❌ Download failed: File contains error message"
            head -3 "${dest}" 2>/dev/null
            rm -f "${dest}" 2>/dev/null
            return 1
        fi
    fi
    
    # Verify minimum sizes for expected files
    case "${filename}" in
        model.safetensors|weights.safetensors)
            if [ "${size}" -lt 1000000 ]; then  # Less than 1MB is suspicious
                echo "⚠️  Warning: ${filename} is very small (${size} bytes). Expected ~2GB+"
                echo "   This might be an error. Check the file manually."
            fi
            ;;
        config.json)
            if [ "${size}" -lt 100 ]; then  # Less than 100 bytes is suspicious
                echo "⚠️  Warning: config.json is very small (${size} bytes). Expected ~1-5KB"
            fi
            ;;
        tokenizer.json)
            if [ "${size}" -lt 1000 ]; then  # Less than 1KB is suspicious
                echo "⚠️  Warning: tokenizer.json is very small (${size} bytes). Expected ~1-5MB"
            fi
            ;;
    esac
    
    echo "✅ Downloaded ${filename} ($(numfmt --to=iec-i --suffix=B ${size} 2>/dev/null || echo "${size} bytes"))"
}

# Download required files
echo ""
echo "Downloading model files..."

# Download model weights file (may be large, ~2GB+)
download_file "model.safetensors" || {
    echo "⚠️  model.safetensors not found, trying alternative names..."
    download_file "weights.safetensors" || download_file "model.safetensors.index.json" || {
        echo "❌ Could not find weights file. Please check Hugging Face repository."
        exit 1
    }
}

# Download config.json
download_file "config.json" || {
    echo "⚠️  config.json not found, trying alternative..."
    download_file "model_config.json" || {
        echo "❌ Could not find config file."
        exit 1
    }
}

# Download tokenizer files (required for proper tokenization)
# Phi-3 may use tokenizer.json (HuggingFace format) or tokenizer.model (SentencePiece)
# Try both - at least one should be available
download_file "tokenizer.json" || {
    echo "⚠️  tokenizer.json not found, trying tokenizer.model..."
    download_file "tokenizer.model" || {
        echo "❌ Neither tokenizer.json nor tokenizer.model found"
        echo "   At least one tokenizer file is required"
        exit 1
    }
}

# Try to download tokenizer.model if tokenizer.json was found (some repos have both)
download_file "tokenizer.model" || {
    echo "ℹ️  tokenizer.model not found (optional if tokenizer.json exists)"
}

# Download tokenizer_config.json (required for swift-transformers)
download_file "tokenizer_config.json" || {
    echo "⚠️  tokenizer_config.json not found (may cause tokenizer loading issues)"
}

# Download additional tokenizer-related files
download_file "added_tokens.json" || {
    echo "ℹ️  added_tokens.json not found (optional)"
}

download_file "special_tokens_map.json" || {
    echo "ℹ️  special_tokens_map.json not found (optional)"
}

# Download chat template (useful for formatting conversations)
download_file "chat_template.jinja" || {
    echo "ℹ️  chat_template.jinja not found (optional, but recommended)"
}

echo ""
echo "✅ Phi-3 Mini model download complete!"
echo "   Files are in: ${MODEL_DIR}"
echo ""
echo "📦 To bundle with the app:"
echo "   1. The files are already in App/Models/"
echo "   2. Run 'make generate' to update Xcode project"
echo "   3. Build the app - files will be included in bundle"
echo ""
echo "💡 Note: Model files are large (~2.3GB). Consider:"
echo "   - Using .gitignore to exclude from git"
echo "   - Using Git LFS if you need version control"
echo "   - Downloading on-demand in production"
echo ""
echo "🧪 To test Phi-3:"
echo "   cd Test && ./run_gemma_test.sh -d ../App/Models/phi-3-mini-4k-instruct-4bit -p 'Hello' -n 20"

