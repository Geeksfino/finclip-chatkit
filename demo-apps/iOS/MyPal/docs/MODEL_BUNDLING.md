# Model Bundling Guide

This guide explains how to bundle the Gemma 270M model with the app for development and testing.

## 📦 Two Approaches

### 1. Bundled Model (Development/Testing)
- Model files included in app bundle
- No download required at runtime
- Faster testing iteration
- Larger app size (~500MB+)

### 2. On-Demand Download (Production)
- Model downloads when switching to Local mode
- Smaller initial app size
- Requires internet connection for first use
- Model stored in Documents directory

## 🚀 Quick Start: Bundle Model for Development

### Step 1: Download Model Files

```bash
cd demo-apps/iOS/MyPal
./scripts/download-model.sh
```

This downloads:
- `weights.safetensors` (~500MB)
- `config.json`
- `tokenizer.json`
- `tokenizer.model` (if available)

To: `App/Models/gemma-270m-it/`

### Step 2: Regenerate Xcode Project

```bash
make generate
```

This includes the Models directory as resources in the Xcode project.

### Step 3: Build and Run

```bash
make run
# or open in Xcode and build
```

The model files will be bundled with the app and available immediately.

## ⚙️ Configuration

In `AppConfig.swift`:

```swift
/// Use bundled model if available (for development/testing)
/// Set to false to always download on-demand
static let preferBundledModel = true
```

- `true` (default): Check bundle first, fall back to download
- `false`: Always download on-demand, ignore bundled model

## 📁 File Structure

```
MyPal/
├── App/
│   └── Models/              # Model files directory
│       └── gemma-270m-it/   # Model-specific directory
│           ├── weights.safetensors
│           ├── config.json
│           └── tokenizer.json
└── scripts/
    └── download-model.sh    # Download script
```

## 🔍 How It Works

### Model Resolution Order

1. **Check Bundle** (if `preferBundledModel = true`)
   - Look in `Bundle.main.resourceURL/Models/gemma-270m-it/`
   - If found, use bundled model

2. **Check Documents** (fallback)
   - Look in `Documents/models/gemma-270m-it/`
   - If found, use downloaded model

3. **Download** (if not found)
   - Download from Hugging Face
   - Save to Documents directory

### Code Flow

```swift
// SceneDelegate.swift
getModelDirectory() 
  → Checks bundle first (if preferBundledModel)
  → Falls back to Documents
  → Returns nil if neither available

isModelDownloaded()
  → Checks if model files exist at resolved directory
  → Returns true if all required files present
```

## 🎯 Use Cases

### Development/Testing
- ✅ Bundle model with app
- ✅ Fast iteration (no download wait)
- ✅ Test offline scenarios
- ✅ Consistent testing environment

### Production
- ✅ Download on-demand
- ✅ Smaller app size
- ✅ Users download only if needed
- ✅ Can update model without app update

## 📝 Git Considerations

### Option 1: Exclude from Git (Recommended)

Add to `.gitignore`:
```
App/Models/
```

**Pros:**
- Keeps repository small
- Each developer downloads once

**Cons:**
- Each developer must run download script
- CI/CD needs to download model

### Option 2: Use Git LFS

```bash
git lfs track "App/Models/**/*.safetensors"
git lfs track "App/Models/**/*.json"
```

**Pros:**
- Model files in version control
- Consistent across team

**Cons:**
- Requires Git LFS setup
- Larger repository

## 🔧 Troubleshooting

### Model Not Found in Bundle

**Check:**
1. Files exist in `App/Models/gemma-270m-it/`
2. Ran `make generate` after adding files
3. Files included in "Copy Bundle Resources" build phase
4. Check Xcode: Target → Build Phases → Copy Bundle Resources

### Download Script Fails

**Common issues:**
- File names may differ on Hugging Face
- Check repository: https://huggingface.co/mlx-community/gemma-270m-it
- Update script with correct file names

### App Size Too Large

**Solutions:**
- Use on-demand download (`preferBundledModel = false`)
- Use quantized model variant (if available)
- Exclude model from release builds

## 📊 File Sizes

Typical Gemma 270M model files:
- `weights.safetensors`: ~500-600MB
- `config.json`: ~1-2KB
- `tokenizer.json`: ~1-5MB
- `tokenizer.model`: ~1-2MB (if present)

**Total:** ~500-600MB

## 🚀 Production Recommendations

1. **Use on-demand download** (`preferBundledModel = false`)
2. **Show download progress** to user
3. **Cache downloaded model** in Documents
4. **Handle download failures** gracefully
5. **Consider model updates** - allow re-download

## 📚 Related

- [HOW_TO_USE_LOCAL_MODE.md](./HOW_TO_USE_LOCAL_MODE.md) - How to use local LLM mode
- [MLX_COMMUNITY_MODELS.md](./MLX_COMMUNITY_MODELS.md) - Available MLX-community models

