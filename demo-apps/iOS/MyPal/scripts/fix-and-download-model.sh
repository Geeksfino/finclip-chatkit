#!/bin/bash
# Fix huggingface-cli and download model
# This script helps fix common huggingface-cli issues and downloads the model

set -e

REPO="mlx-community/gemma-3-270m-it-4bit"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODEL_DIR="${PROJECT_ROOT}/App/Models/gemma-3-270m-it-4bit"

echo "🔧 Checking Hugging Face CLI setup..."

# Try to find working Python
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ Python not found. Please install Python 3.7+"
    exit 1
fi

echo "✓ Using Python: ${PYTHON_CMD}"

# Check if huggingface-hub is installed
if ! ${PYTHON_CMD} -c "import huggingface_hub" 2>/dev/null; then
    echo "📦 Installing huggingface-hub..."
    ${PYTHON_CMD} -m pip install --user huggingface-hub
fi

# Use Python module directly instead of CLI
echo ""
echo "📥 Downloading Gemma 270M model using Python..."
echo "   Repository: ${REPO}"
echo "   Destination: ${MODEL_DIR}"

mkdir -p "${MODEL_DIR}"

# Create a Python script to download
cat > /tmp/download_model.py << 'PYTHON_SCRIPT'
import sys
from huggingface_hub import hf_hub_download
import os

repo_id = sys.argv[1]
local_dir = sys.argv[2]
files = sys.argv[3:]

for filename in files:
    try:
        print(f"📥 Downloading {filename}...")
        downloaded_path = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            local_dir=local_dir,
            local_dir_use_symlinks=False
        )
        size = os.path.getsize(downloaded_path)
        print(f"✅ Downloaded {filename} ({size:,} bytes)")
    except Exception as e:
        print(f"⚠️  {filename} not found: {e}")
        if filename == "weights.safetensors":
            # Try alternatives
            for alt in ["model.safetensors", "pytorch_model.bin"]:
                try:
                    print(f"   Trying {alt}...")
                    downloaded_path = hf_hub_download(
                        repo_id=repo_id,
                        filename=alt,
                        local_dir=local_dir,
                        local_dir_use_symlinks=False
                    )
                    size = os.path.getsize(downloaded_path)
                    print(f"✅ Downloaded {alt} ({size:,} bytes)")
                    break
                except:
                    continue
            else:
                print(f"❌ Could not find weights file")
                sys.exit(1)
PYTHON_SCRIPT

# Download files
${PYTHON_CMD} /tmp/download_model.py "${REPO}" "${MODEL_DIR}" \
    "weights.safetensors" \
    "config.json" \
    "tokenizer.json" \
    "tokenizer.model"

# Clean up
rm -f /tmp/download_model.py

echo ""
echo "✅ Model download complete!"
echo "   Files are in: ${MODEL_DIR}"
echo ""
echo "📦 Next steps:"
echo "   1. Run 'make generate' to update Xcode project"
echo "   2. Build the app - files will be included in bundle"

