#!/bin/bash
# Organize manually downloaded files into the correct location
# Run this after downloading files from Hugging Face

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODEL_DIR="${PROJECT_ROOT}/App/Models/gemma-270m-it"
DOWNLOADS_DIR="${HOME}/Downloads"

echo "📁 Organizing downloaded model files..."
echo "   Looking in: ${DOWNLOADS_DIR}"
echo "   Destination: ${MODEL_DIR}"
echo ""

# Create destination directory
mkdir -p "${MODEL_DIR}"

# Function to find and move a file
move_file() {
    local filename=$1
    local source="${DOWNLOADS_DIR}/${filename}"
    
    if [ -f "${source}" ]; then
        echo "✅ Found ${filename}"
        mv "${source}" "${MODEL_DIR}/"
        echo "   Moved to ${MODEL_DIR}/${filename}"
        return 0
    else
        echo "⚠️  ${filename} not found in Downloads"
        return 1
    fi
}

# Try to find and move files
echo "Searching for model files..."
echo ""

found_any=false

if move_file "weights.safetensors"; then
    found_any=true
fi

if move_file "config.json"; then
    found_any=true
fi

if move_file "tokenizer.json"; then
    found_any=true
fi

if move_file "tokenizer.model"; then
    found_any=true
fi

echo ""
if [ "$found_any" = true ]; then
    echo "✅ Files organized!"
    echo ""
    echo "📊 Current files:"
    ls -lh "${MODEL_DIR}/" 2>/dev/null || echo "   (directory is empty)"
    echo ""
    echo "💡 If some files are missing, you can:"
    echo "   1. Download them from: https://huggingface.co/mlx-community/gemma-270m-it"
    echo "   2. Place them in: ${MODEL_DIR}"
    echo "   3. Run this script again"
else
    echo "❌ No model files found in Downloads folder"
    echo ""
    echo "Please:"
    echo "1. Download files from: https://huggingface.co/mlx-community/gemma-270m-it"
    echo "2. Save them to: ${DOWNLOADS_DIR}"
    echo "3. Run this script again"
    echo ""
    echo "Or manually copy files to: ${MODEL_DIR}"
fi

