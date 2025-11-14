#!/bin/bash
# Helper script to open Hugging Face repository in browser for manual download
# This opens the repository and provides instructions

REPO="mlx-community/gemma-270m-it"
REPO_URL="https://huggingface.co/${REPO}"

echo "🌐 Opening Hugging Face repository in browser..."
echo ""
echo "Repository: ${REPO_URL}"
echo ""
echo "📋 Instructions:"
echo "1. Click 'Files and versions' tab"
echo "2. For each file, click the download button (⬇️) or right-click → Save"
echo "3. Download these files:"
echo "   - weights.safetensors (~500MB)"
echo "   - config.json"
echo "   - tokenizer.json"
echo "   - tokenizer.model (if available)"
echo ""
echo "4. After downloading, run:"
echo "   ./scripts/organize-downloaded-files.sh"
echo ""

# Open in default browser
if command -v open &> /dev/null; then
    open "${REPO_URL}"
elif command -v xdg-open &> /dev/null; then
    xdg-open "${REPO_URL}"
else
    echo "Please open: ${REPO_URL}"
fi

