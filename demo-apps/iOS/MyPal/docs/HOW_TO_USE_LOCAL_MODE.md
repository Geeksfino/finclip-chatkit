# How to Use Local LLM Mode

## Current Issue

The app starts in **Remote mode** by default. When you send a message, it tries to connect to a remote server at `http://127.0.0.1:3000/agent`, which fails on a physical device.

## Solution: Switch to Local Mode

### Step 1: Rebuild the App

The model files need to be bundled with the app:

```bash
cd /Users/cliang/repos/finclip/finclip-chatkit/demo-apps/iOS/MyPal
make generate
# Then build in Xcode
```

### Step 2: Switch to Local Mode

1. **Open the app** on your physical device
2. **Look for the mode toggle button** in the top bar (should show "Remote" with a cloud icon)
3. **Tap the mode toggle button**
4. **Select "Local LLM (Gemma 270M)"** from the action sheet
5. **Wait for model to load** (check console for loading messages)

### Step 3: Send a Message

After switching to local mode and the model loads, send a message. It should use the local Gemma model instead of trying to connect to a remote server.

## Expected Console Output

When switching to local mode, you should see:

```
🔧 [SceneDelegate] App initialized in REMOTE mode
   💡 To use local LLM, tap the mode toggle button and select 'Local LLM (Gemma 270M)'
🔍 [SceneDelegate] Checking bundled model availability...
📦 [SceneDelegate] Using bundled model from app bundle
⏳ [SceneDelegate] Starting model load - this may take 10-30 seconds...
📦 [LocalLLMModelManager] Loading model...
⚖️  [LocalLLMModelManager] Model weights loaded: X tensors
📝 [LocalLLMModelManager] Tokenizer loaded
✅ [LocalLLMModelManager] Model loaded successfully
✅ [SceneDelegate] Local LLM adapter configured
```

## Troubleshooting

### Model Not Found

If you see `❌ [SceneDelegate] Could not determine model path`:

1. **Check if model files are bundled:**
   - The model folder should be in `App/Models/gemma-3-270m-it-4bit/`
   - Files needed: `model.safetensors`, `config.json`, `tokenizer.json`, `tokenizer.model`

2. **Verify in Xcode:**
   - Check that `App/Models/gemma-3-270m-it-4bit` appears in the project navigator
   - Check that it's included in "Copy Bundle Resources" build phase

3. **Check console logs:**
   - Look for `🔍 [SceneDelegate] Checking bundled model at: ...`
   - Check what files are found in the directory

### Still Getting "Could not connect to server"

- Make sure you've switched to local mode (check the mode toggle button shows "Local")
- Check console for model loading errors
- Verify the model files are in the app bundle

## Next Steps

Once local mode is working, you should see:
- Model loads successfully
- Messages generate responses using the local Gemma model
- No network connection errors

