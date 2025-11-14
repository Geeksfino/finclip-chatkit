# MLX-Community Gemma Models

## Available Models

Based on search results, the actual MLX-community Gemma models appear to be:

1. **mlx-community/gemma-3-270m-bf16** - Gemma 3 270M in bf16 format
2. **mlx-community/gemma-2-270m-it** - Gemma 2 270M instruction-tuned (if available)
3. **mlx-community/gemma-270m** - Base Gemma 270M (if available)

## Issue

The repository `mlx-community/gemma-270m-it` doesn't exist (404 error).

## Solutions

### Option 1: Use gemma-3-270m-bf16

This model exists and is in MLX format:
- Repository: `mlx-community/gemma-3-270m-bf16`
- Format: bf16 (should work with MLX)

### Option 2: Try gemma-2-270m-it

If available:
- Repository: `mlx-community/gemma-2-270m-it`
- Format: Instruction-tuned version

### Option 3: Convert Google Model

If MLX-community doesn't have the exact model, we can:
1. Download from `google/gemma-3-270m-it`
2. Convert to MLX format using Python

### Option 4: Use Different Model Size

Try a smaller model first to test:
- `mlx-community/gemma-2b-it` (if available)
- Or stick with Google model and fix the conversion

## Next Steps

1. Check what models actually exist
2. Update AppConfig with correct repository
3. Try downloading the correct model

