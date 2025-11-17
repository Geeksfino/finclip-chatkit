#!/bin/bash
#
# Convenience script to run GemmaTestApp from command line with parameter control
#
# Usage:
#   ./run_gemma_test.sh -p "Hello" -n 50 -T 0.7 -k 50
#   ./run_gemma_test.sh --prompt "Hello" --max-tokens 50 --temperature 0.7 --top-k 50
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="/Users/cliang/Library/Developer/Xcode/DerivedData/GemmaTestApp-flkdjvqjvewupsfqakrnpwkajwmk/Build/Products/Debug/GemmaTestApp.app/Contents/MacOS/GemmaTestApp"

DEFAULT_MODEL_PATH="../App/Models/gemma-3-270m-it-4bit"
MODEL_PATH="$DEFAULT_MODEL_PATH"
PROMPT="Hello"
MAX_TOKENS=50
TEMPERATURE=0.7
TOP_K=50

print_help() {
  cat <<USAGE
Usage: $0 [options]

Options:
  -d, --model-path PATH    Path to model directory (default: $DEFAULT_MODEL_PATH)
  -p, --prompt TEXT        Prompt text (default: "$PROMPT")
  -n, --max-tokens N       Max new tokens to generate (default: $MAX_TOKENS)
  -T, --temperature VAL    Sampling temperature (default: $TEMPERATURE)
  -k, --top-k N            Top-k parameter (default: $TOP_K)
  -h, --help               Show this message

Examples:
  $0 -p "Hello, how are you?" -n 100
  $0 --model-path /path/to/model --prompt "Test" --max-tokens 20 --temperature 0.5
USAGE
}

# Parse arguments
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--model-path)
      MODEL_PATH="$2"
      ARGS+=("--model-path" "$2")
      shift 2
      ;;
    -p|--prompt)
      PROMPT="$2"
      ARGS+=("--prompt" "$2")
      shift 2
      ;;
    -n|--max-tokens)
      MAX_TOKENS="$2"
      ARGS+=("--max-tokens" "$2")
      shift 2
      ;;
    -T|--temperature)
      TEMPERATURE="$2"
      ARGS+=("--temperature" "$2")
      shift 2
      ;;
    -k|--top-k)
      TOP_K="$2"
      ARGS+=("--top-k" "$2")
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_help
      exit 1
      ;;
  esac
done

# Check if app exists
if [ ! -f "$APP_PATH" ]; then
    echo "Error: GemmaTestApp not found at $APP_PATH" >&2
    echo "Please build the app first using:" >&2
    echo "  cd GemmaTestApp && xcodebuild -workspace GemmaTestApp.xcworkspace -scheme GemmaTestApp -configuration Debug" >&2
    exit 1
fi

# Change to script directory so relative paths work
cd "$SCRIPT_DIR"

# Run the app with arguments
exec "$APP_PATH" "${ARGS[@]}"
