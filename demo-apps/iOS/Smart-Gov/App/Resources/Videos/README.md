# Splash Video

## Adding Your Splash Video

To enable the splash screen video:

1. **Add your video file** to this directory
2. **Name it** `splash.mp4`
3. **Rebuild** the project using `make build` or regenerate with XcodeGen

## Video Requirements

- **Format**: MP4 (H.264 codec recommended)
- **Duration**: 2-5 seconds recommended for best user experience
- **Resolution**: 1080x1920 (portrait) or higher
- **File size**: Keep under 5MB for fast loading
- **Aspect ratio**: Video will scale to fill screen (aspect fill)

## Behavior

- Video plays automatically on app launch
- User can **tap anywhere** to skip the video
- After video completes, app transitions to main interface
- If video file is missing, app launches directly (no splash screen)

## Example Video Creation

You can create a simple splash video using:
- **macOS**: iMovie, Final Cut Pro, or QuickTime Player
- **Online tools**: Canva, Adobe Express
- **Command line**: ffmpeg

Example ffmpeg command to convert/resize:
```bash
ffmpeg -i input.mov -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 128k splash.mp4
```

## Testing

After adding the video:
1. Run `make build` to regenerate the Xcode project
2. Build and run the app
3. The splash video should play on launch
4. Tap to skip or wait for completion
