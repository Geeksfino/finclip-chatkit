#!/bin/bash
# Helper script to run the GemmaTest CLI with convenient parameter flags.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_MODEL_PATH="../App/Models/gemma-3-270m-it-4bit"
MODEL_PATH="$DEFAULT_MODEL_PATH"
PROMPT="Hello"
MAX_TOKENS=50
TEMPERATURE=0.7
TOP_K=50
CUSTOM_METAL_PATH=""

print_help() {
  cat <<USAGE
Usage: $0 [options]
  -d, --model-path PATH    Path to model directory (default: $DEFAULT_MODEL_PATH)
  -p, --prompt TEXT        Prompt text (default: "$PROMPT")
  -n, --max-tokens N       Max new tokens to generate (default: $MAX_TOKENS)
  -T, --temperature VAL    Sampling temperature (default: $TEMPERATURE)
  -k, --top-k N            Top-k parameter (default: $TOP_K)
  -m, --metal-path PATH    Explicit MLX Metal library path (default: auto-detect)
  -h, --help               Show this message
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--model-path) MODEL_PATH="$2"; shift 2;;
    -p|--prompt) PROMPT="$2"; shift 2;;
    -n|--max-tokens) MAX_TOKENS="$2"; shift 2;;
    -T|--temperature) TEMPERATURE="$2"; shift 2;;
    -k|--top-k) TOP_K="$2"; shift 2;;
    -m|--metal-path) CUSTOM_METAL_PATH="$2"; shift 2;;
    -h|--help) print_help; exit 0;;
    *) echo "Unknown option: $1" >&2; print_help; exit 1;;
  esac
done

locate_default_metallib() {
  local roots=("$SCRIPT_DIR" "$SCRIPT_DIR/.." "$SCRIPT_DIR/../build" "$SCRIPT_DIR/../../build")
  for root in "${roots[@]}"; do
    if [[ -d "$root" ]]; then
      local found
      found=$(find "$root" -name default.metallib -print -quit 2>/dev/null || true)
      if [[ -n "$found" ]]; then
        echo "$found"
        return
      fi
    fi
  done
  return 1
}

setup_mlx_metal() {
  if [[ -n "$CUSTOM_METAL_PATH" ]]; then
    if [[ -f "$CUSTOM_METAL_PATH" ]]; then
      export MLX_METAL_PATH="$CUSTOM_METAL_PATH"
      echo "[run_gemma_cli] Using MLX_METAL_PATH=$MLX_METAL_PATH (custom)"
      return
    else
      echo "[run_gemma_cli] Provided metal path not found: $CUSTOM_METAL_PATH" >&2
      exit 1
    fi
  fi

  if [[ -n "${MLX_METAL_PATH:-}" && -f "$MLX_METAL_PATH" ]]; then
    echo "[run_gemma_cli] Using existing MLX_METAL_PATH=$MLX_METAL_PATH"
    return
  fi

  local candidate
  candidate=$(locate_default_metallib || true)
  if [[ -n "$candidate" ]]; then
    export MLX_METAL_PATH="$candidate"
    echo "[run_gemma_cli] Auto-detected MLX_METAL_PATH=$MLX_METAL_PATH"
    return
  fi

  echo "[run_gemma_cli] Could not find default.metallib. Run 'swift build' first or specify --metal-path." >&2
  exit 1
}

setup_mlx_metal

swift run GemmaTest \
  --model-path "$MODEL_PATH" \
  --prompt "$PROMPT" \
  --max-tokens "$MAX_TOKENS" \
  --temperature "$TEMPERATURE" \
  --top-k "$TOP_K"
