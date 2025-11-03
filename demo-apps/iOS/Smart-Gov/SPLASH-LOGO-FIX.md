# Splash Screen and Logo Fix

## Issues Diagnosed

### 1. Splash Screen Not Loading
**Root Cause:** The `App/Resources/Videos` directory was not included in `project.yml` resources section, so the splash video (`splash.MP4`) was not being bundled with the app.

**Fix:** Added `Videos` directory to resources in `project.yml`:
```yaml
resources:
  - path: App/Resources/Assets.xcassets
  - path: App/Resources/Videos
    type: folder
  - path: App/Resources/Fixtures
    type: folder
```

### 2. Logo Not Displaying
**Root Cause:** The logo asset (`AppLogo`) exists in `Assets.xcassets` and should work, but verification needed.

**Status:** Logo file exists at `App/Resources/Assets.xcassets/AppLogo.imageset/AppLogo.png` and is correctly referenced in code as `UIImage(named: "AppLogo")`. Since `Assets.xcassets` is included in resources, this should work after regenerating the project.

## Changes Made

1. **Updated `project.yml`**:
   - Added `App/Resources/Videos` as a folder resource
   - Added `App/Resources/Fixtures` as a folder resource (for completeness)
   - Used explicit `path` and `type: folder` syntax for clarity

## Verification Steps

1. ✅ Regenerated project: `make generate`
2. ⏳ Build and run: `make run`
3. ⏳ Verify splash video plays on launch
4. ⏳ Verify logo displays in empty state

## Expected Behavior

- **Splash Screen**: Video should play automatically on app launch (or skip on tap)
- **Logo**: Should display in the empty state view when no conversation is selected

## Notes

- The splash video file is named `splash.MP4` (uppercase), but the code handles both cases
- The code searches for video in `Videos` subdirectory first, then bundle root
- Logo is loaded from asset catalog as `AppLogo`
