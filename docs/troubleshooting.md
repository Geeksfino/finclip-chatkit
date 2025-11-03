# Troubleshooting Guide

This guide covers common issues encountered when integrating ChatKit and their solutions, based on real debugging experiences.

## Build Issues

### "Framework not found" or "No such module" errors

**Symptoms:**
- Build fails with "No such module 'ConvoUI'"
- Linker errors about missing frameworks
- Runtime crashes with "image not found"

**Root Cause:**
The framework name in search paths is incorrect. The actual embedded framework is named `FinClipChatKit.framework`, not `ChatKit.framework`.

**Solution:**
Update all framework references in your build settings:

```yaml
# In project.yml settings:
FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
LD_RUNPATH_SEARCH_PATHS: $(inherited) @executable_path/Frameworks @loader_path/Frameworks @loader_path/Frameworks/FinClipChatKit.framework/Frameworks
SWIFT_INCLUDE_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
```

### Package name mismatch

**Symptoms:**
- XcodeGen fails with package resolution errors
- Dependency not found errors

**Root Cause:**
Package name in project.yml doesn't match the actual package name.

**Solution:**
Use `ChatKit` as the package name:

```yaml
packages:
  ChatKit:  # NOT "finclip-chatkit"
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.1.0
```

### Version mismatch

**Symptoms:**
- Package resolution fails
- Incompatible versions

**Solution:**
Use version `0.1.0` consistently:

```yaml
from: 0.1.0
```

## Configuration Issues

### Missing build settings

**Symptoms:**
- Build succeeds but app crashes on launch
- Framework loading errors

**Required Settings:**
```yaml
settings:
  PRODUCT_NAME: YourAppName
  INFOPLIST_KEY_CFBundleDisplayName: YourAppName
  ENABLE_BITCODE: NO
  # Framework search paths (see above)
```

### Resources configuration

**Symptoms:**
- Asset catalog issues
- Missing resources

**Solution:**
Use simple resources format:

```yaml
resources:
  - App/Resources/Assets.xcassets
```

Avoid complex `assetCatalogs` configuration unless specifically needed.

## Runtime Issues

### Framework signing issues

**Symptoms:**
- App crashes on launch
- "Code signature invalid" errors

**Solution:**
Add post-build script to sign nested frameworks:

```yaml
postbuildScripts:
  - name: Sign Nested Frameworks
    shell: /bin/sh
    script: |
      FRAMEWORK_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/FinClipChatKit.framework/Frameworks"
      if [ -d "${FRAMEWORK_DIR}" ]; then
        find "${FRAMEWORK_DIR}" -type d -name "*.framework" -print0 | while IFS= read -r -d '' FRAME; do
          /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "${FRAME}" || exit 1
        done
      fi
```

## Environment Setup

### Prerequisites verification

```bash
# Check Xcode version
xcodebuild -version

# Check XcodeGen
xcodegen version

# Check CocoaPods
pod --version
```

### Common commands

```bash
# Generate project
make generate

# Build with CocoaPods
make run-cocoapods

# Build with SPM
make run

# Clean everything
make clean

# Test dependencies
make validate-deps
```

## Debugging Checklist

When encountering build issues:

1. ✅ Verify framework name is `FinClipChatKit.framework` in all paths
2. ✅ Check package name is `ChatKit` in project.yml
3. ✅ Ensure version is `0.1.0`
4. ✅ Confirm all framework search paths are set
5. ✅ Verify post-build script is configured
6. ✅ Check that PRODUCT_NAME and display name are set
7. ✅ Ensure deployment target is iOS 16.0+

## Real-World Debugging Example

**Problem:** Smart-Gov wasn't compiling
**Root Cause:** Framework name was `ChatKit.framework` instead of `FinClipChatKit.framework`
**Solution:** Updated all references to use `FinClipChatKit.framework`

**Before (broken):**
```yaml
FRAMEWORK_SEARCH_PATHS: $(BUILT_PRODUCTS_DIR)/ChatKit.framework/Frameworks
```

**After (working):**
```yaml
FRAMEWORK_SEARCH_PATHS: $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
```

## Support Resources

- **Smart-Gov example** - Complete working reference implementation
- **AI-Bank example** - Verified working configuration
- **GitHub Issues** - Report bugs or ask questions
- **Documentation** - Comprehensive guides and references
