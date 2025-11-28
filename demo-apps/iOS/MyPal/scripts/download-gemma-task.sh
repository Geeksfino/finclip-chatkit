#!/bin/bash
# Download Gemma-3 270M MediaPipe model file (.task format) from Kaggle
# This script downloads the MediaPipe-compatible model file for use with Google's LLM Inference API

set -e

# Kaggle dataset identifier (update this with the actual dataset path)
# Format: <username>/<dataset-name>
KAGGLE_DATASET="${KAGGLE_DATASET:-google/gemma-3-270m-it-int8}"
MODEL_FILE="gemma-3-270m-it-int8.task"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODEL_DIR="${PROJECT_ROOT}/App/Models"
MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"

echo "📥 Downloading Gemma-3 270M MediaPipe model from Kaggle..."
echo "   Dataset: ${KAGGLE_DATASET}"
echo "   File: ${MODEL_FILE}"
echo "   Destination: ${MODEL_PATH}"

# Check if kaggle CLI is installed
if ! command -v kaggle &> /dev/null; then
    echo "❌ Kaggle CLI not found!"
    echo ""
    echo "💡 Install Kaggle CLI with:"
    echo "   pip install kaggle"
    echo ""
    echo "💡 Then configure your API credentials:"
    echo "   1. Go to https://www.kaggle.com/settings"
    echo "   2. Click 'Create New API Token' to download kaggle.json"
    echo "   3. Place it at ~/.kaggle/kaggle.json"
    echo "   4. Run: chmod 600 ~/.kaggle/kaggle.json"
    exit 1
fi

# Check if Kaggle credentials exist
if [ ! -f "${HOME}/.kaggle/kaggle.json" ]; then
    echo "⚠️  Kaggle credentials not found at ~/.kaggle/kaggle.json"
    echo ""
    echo "💡 To set up Kaggle API credentials:"
    echo "   1. Go to https://www.kaggle.com/settings"
    echo "   2. Click 'Create New API Token' to download kaggle.json"
    echo "   3. Place it at ~/.kaggle/kaggle.json"
    echo "   4. Run: chmod 600 ~/.kaggle/kaggle.json"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create model directory
mkdir -p "${MODEL_DIR}"

# Check if file already exists
if [ -f "${MODEL_PATH}" ]; then
    FILE_SIZE=$(du -h "${MODEL_PATH}" | cut -f1)
    echo "⚠️  Model file already exists: ${MODEL_PATH} (${FILE_SIZE})"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "✅ Keeping existing file"
        exit 0
    fi
    echo "🗑️  Removing existing file..."
    rm -f "${MODEL_PATH}"
fi

# Download from Kaggle
echo "📥 Downloading from Kaggle..."
echo "   This may take a while depending on your internet connection..."

# Try to download the specific file
if kaggle datasets download -d "${KAGGLE_DATASET}" -f "${MODEL_FILE}" -p "${MODEL_DIR}" --unzip; then
    echo "✅ Download successful!"
    
    # Verify file exists
    if [ -f "${MODEL_PATH}" ]; then
        FILE_SIZE=$(du -h "${MODEL_PATH}" | cut -f1)
        echo "✅ Model file verified: ${MODEL_PATH} (${FILE_SIZE})"
    else
        echo "⚠️  Downloaded file not found at expected location"
        echo "   Checking for downloaded files in ${MODEL_DIR}..."
        ls -lh "${MODEL_DIR}" | grep -i "\.task" || echo "   No .task files found"
    fi
else
    echo "❌ Download failed!"
    echo ""
    echo "💡 Troubleshooting:"
    echo "   1. Verify the dataset path is correct: ${KAGGLE_DATASET}"
    echo "   2. Check if you have access to the dataset"
    echo "   3. Verify your Kaggle API credentials"
    echo "   4. Try running: kaggle datasets list -s gemma"
    exit 1
fi

# Clean up any zip files that might have been created
if [ -f "${MODEL_DIR}/${MODEL_FILE}.zip" ]; then
    echo "🧹 Cleaning up zip file..."
    rm -f "${MODEL_DIR}/${MODEL_FILE}.zip"
fi

echo ""
echo "✅ Download complete!"
echo "   Model file: ${MODEL_PATH}"
echo ""
echo "💡 Next steps:"
echo "   1. Run 'make generate' to update Xcode project"
echo "   2. Build and run the app to test the model"

