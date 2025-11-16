# Build Tooling Guide

This guide covers the tools and workflows for building ChatKit apps reproducibly. These tools ensure consistent builds across different environments and are essential for AI agents and automated workflows.

---

## Overview

ChatKit demo apps use a standardized build system:

- **XcodeGen** - Generates Xcode projects from YAML configuration
- **Makefile** - Standardized build commands
- **project.yml** - Project configuration (dependencies, settings, sources)
- **xcrun simctl** - Simulator management

This approach provides:
- ✅ Reproducible builds
- ✅ Version-controlled project configuration
- ✅ Easy environment setup
- ✅ AI agent-friendly workflows

---

## Prerequisites

### Required Tools

```bash
# Install XcodeGen
brew install xcodegen

# Verify installation
xcodegen --version
```

### Xcode Command Line Tools

```bash
# Install if not already present
xcode-select --install
```

---

## XcodeGen

### What is XcodeGen?

XcodeGen generates Xcode projects from YAML files (`project.yml`). This allows:
- Version-controlling project structure
- Reproducible project generation
- Avoiding Xcode project merge conflicts
- Consistent project configuration

### Basic Usage

```bash
# Generate Xcode project from project.yml
xcodegen generate --spec project.yml

# Or use the Makefile target
make generate
```

### Installation

```bash
brew install xcodegen
```

---

## project.yml Structure

The `project.yml` file defines your entire Xcode project structure.

### Basic Structure

```yaml
name: MyChatApp
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "16.0"

schemes:
  MyChatApp:
    build:
      targets:
        MyChatApp: all
    run:
      config: Debug

packages:
  ChatKit:
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.7.4

targets:
  MyChatApp:
    type: application
    platform: iOS
    sources:
      - path: App/App
      - path: App/ViewControllers
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.example.mychatapp
      PRODUCT_NAME: MyChatApp
      INFOPLIST_FILE: App/App/Info.plist
      ENABLE_BITCODE: NO
    dependencies:
      - package: ChatKit
```

### Key Sections

#### 1. Project Metadata

```yaml
name: MyChatApp
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "16.0"
```

#### 2. Package Dependencies

```yaml
packages:
  ChatKit:
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.7.4
```

#### 3. Target Configuration

```yaml
targets:
  MyChatApp:
    type: application
    platform: iOS
    sources:
      - path: App/App
      - path: App/ViewControllers
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.example.mychatapp
      INFOPLIST_FILE: App/App/Info.plist
    dependencies:
      - package: ChatKit
```

#### 4. Framework Search Paths

For ChatKit's nested frameworks:

```yaml
settings:
  FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
  FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
  LD_RUNPATH_SEARCH_PATHS: $(inherited) @executable_path/Frameworks @loader_path/Frameworks @loader_path/Frameworks/FinClipChatKit.framework/Frameworks
  SWIFT_INCLUDE_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
  SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
```

#### 5. Post-Build Scripts

For signing nested frameworks:

```yaml
postbuildScripts:
  - name: Sign Nested ChatKit Frameworks
    shell: /bin/sh
    script: |
      FRAMEWORK_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/FinClipChatKit.framework/Frameworks"
      if [ -d "${FRAMEWORK_DIR}" ]; then
        find "${FRAMEWORK_DIR}" -type d -name "*.framework" -print0 | while IFS= read -r -d '' FRAME; do
          /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "${FRAME}" || exit 1
        done
      fi
```

### Complete Example

See `demo-apps/iOS/Simple/project.yml` for a complete working example.

---

## Makefile Patterns

### Standard Makefile Structure

```makefile
PROJECT_NAME=MyChatApp
PROJECT_FILE=$(PROJECT_NAME).xcodeproj
SIMULATOR_DEVICE?=iPhone 17
SIMULATOR_DESTINATION?=platform=iOS Simulator,name=$(SIMULATOR_DEVICE)

.PHONY: generate open clean deep-clean run

generate:
	@if ! command -v xcodegen >/dev/null 2>&1; then \
		echo "❌ XcodeGen not installed. Install with 'brew install xcodegen'."; \
		exit 1; \
	fi
	@echo "🔧 Generating Xcode project..."
	xcodegen generate --spec project.yml
	@echo "✅ Project generated: $(PROJECT_FILE)"

open: generate
	@echo "📂 Opening $(PROJECT_FILE)..."
	xed "$(PROJECT_FILE)"

run: generate
	@echo "🚀 Building and running $(PROJECT_NAME) on iOS simulator..."
	xcodebuild \
	  -project "$(PROJECT_FILE)" \
	  -scheme "$(PROJECT_NAME)" \
	  -destination '$(SIMULATOR_DESTINATION)' \
	  -configuration Debug \
	  -derivedDataPath build/DerivedData \
	  build
	APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/$(PROJECT_NAME).app"; \
	if [ ! -d "$$APP_PATH" ]; then \
		echo "❌ Built app not found at $$APP_PATH"; \
		exit 1; \
	fi; \
	xcrun simctl boot "$(SIMULATOR_DEVICE)" >/dev/null 2>&1 || true; \
	xcrun simctl install booted "$$APP_PATH"; \
	xcrun simctl launch booted com.example.mychatapp
	@echo "✅ $(PROJECT_NAME) launched on simulator"

clean:
	@echo "🧹 Cleaning generated project and local build outputs..."
	rm -rf "$(PROJECT_FILE)" "$(PROJECT_NAME).xcworkspace"
	rm -rf build
	@echo "✅ Clean complete"

deep-clean: clean
	@echo "🧼 Removing simulator-installed app (if any)..."
	- xcrun simctl uninstall booted com.example.mychatapp >/dev/null 2>&1 || true
	@echo "✅ Deep clean complete"
```

### Makefile Targets

#### `make generate`
Generates Xcode project from `project.yml`.

**What it does**:
1. Checks if XcodeGen is installed
2. Runs `xcodegen generate --spec project.yml`
3. Creates `.xcodeproj` file

**Expected output**:
```
🔧 Generating Xcode project...
⚙️  Generating plists...
⚙️  Generating project...
⚙️  Writing project...
Created project at /path/to/MyChatApp.xcodeproj
✅ Project generated: MyChatApp.xcodeproj
```

#### `make open`
Generates project (if needed) and opens it in Xcode.

**What it does**:
1. Calls `make generate` if project doesn't exist
2. Opens project with `xed` (Xcode command-line tool)

#### `make run`
Builds and runs the app on simulator.

**What it does**:
1. Generates project (if needed)
2. Builds with `xcodebuild`
3. Boots simulator (if not running)
4. Installs app
5. Launches app

**Expected output**:
```
🚀 Building and running MyChatApp on iOS simulator...
[Build output...]
✅ MyChatApp launched on simulator
```

#### `make clean`
Removes generated project and build artifacts.

**What it removes**:
- `.xcodeproj` directory
- `.xcworkspace` directory
- `build/` directory

#### `make deep-clean`
Removes everything from `clean` plus uninstalls app from simulator.

---

## xcodebuild

### Building Projects

```bash
# Build for simulator
xcodebuild \
  -project MyChatApp.xcodeproj \
  -scheme MyChatApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  build
```

### Key Parameters

- `-project`: Path to `.xcodeproj` file
- `-scheme`: Scheme name (usually matches project name)
- `-destination`: Simulator or device target
- `-configuration`: Debug or Release
- `-derivedDataPath`: Where to store build artifacts

### Common Destinations

```bash
# iPhone 17 Simulator
-destination 'platform=iOS Simulator,name=iPhone 17'

# Any available iPhone simulator
-destination 'platform=iOS Simulator,name=iPhone'

# Physical device (requires connected device)
-destination 'platform=iOS,id=<device-id>'
```

---

## xcrun simctl

### Simulator Management

#### List Available Simulators

```bash
xcrun simctl list devices available
```

**Expected output**:
```
== Devices ==
iPhone 17 (12345678-1234-1234-1234-123456789012) (Shutdown)
iPhone 16 Pro (87654321-4321-4321-4321-210987654321) (Shutdown)
```

#### Boot Simulator

```bash
xcrun simctl boot "iPhone 17"
```

**Note**: Boots simulator if not already running. Use `> /dev/null 2>&1 || true` to suppress errors if already booted.

#### Install App

```bash
xcrun simctl install booted /path/to/MyChatApp.app
```

**Note**: `booted` refers to the currently booted simulator.

#### Launch App

```bash
xcrun simctl launch booted com.example.mychatapp
```

**Note**: Requires bundle identifier from `Info.plist` or `PRODUCT_BUNDLE_IDENTIFIER` setting.

#### Uninstall App

```bash
xcrun simctl uninstall booted com.example.mychatapp
```

#### Shutdown Simulator

```bash
xcrun simctl shutdown booted
```

---

## Reproducible Build Workflow

### Step-by-Step Process

#### 1. Environment Setup

```bash
# Install XcodeGen
brew install xcodegen

# Verify tools
xcodegen --version
xcodebuild -version
xcrun simctl list devices
```

#### 2. Generate Project

```bash
cd /path/to/your/app
make generate
```

**Expected result**: `.xcodeproj` file created

#### 3. Build App

```bash
make run
```

**What happens**:
1. Project generated (if needed)
2. App built with xcodebuild
3. Simulator booted (if needed)
4. App installed
5. App launched

#### 4. Clean Up

```bash
make clean        # Remove build artifacts
make deep-clean   # Also uninstall from simulator
```

### Complete Workflow Example

```bash
# 1. Navigate to project
cd demo-apps/iOS/Simple

# 2. Generate Xcode project
make generate

# 3. Build and run
make run

# 4. When done, clean up
make deep-clean
```

---

## AI Agent Workflow

For AI agents or automated systems, use this structured workflow:

### 1. Check Prerequisites

```bash
# Check XcodeGen
if ! command -v xcodegen >/dev/null 2>&1; then
    echo "Installing XcodeGen..."
    brew install xcodegen
fi

# Check Xcode
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Xcode not found. Please install Xcode."
    exit 1
fi
```

### 2. Generate Project

```bash
cd /path/to/project
xcodegen generate --spec project.yml
```

**Expected**: `.xcodeproj` created, exit code 0

### 3. Build Project

```bash
xcodebuild \
  -project MyChatApp.xcodeproj \
  -scheme MyChatApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  build
```

**Expected**: Build succeeds, exit code 0

### 4. Verify Build Output

```bash
APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/MyChatApp.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Build failed: app not found"
    exit 1
fi
```

### 5. Run on Simulator

```bash
# Boot simulator
xcrun simctl boot "iPhone 17" >/dev/null 2>&1 || true

# Install app
xcrun simctl install booted "$APP_PATH"

# Launch app
xcrun simctl launch booted com.example.mychatapp
```

---

## Troubleshooting

### XcodeGen Not Found

**Error**: `xcodegen: command not found`

**Solution**:
```bash
brew install xcodegen
```

### Project Generation Fails

**Error**: `Error: ...`

**Check**:
1. `project.yml` syntax is valid YAML
2. All referenced source paths exist
3. Package URLs are accessible

**Debug**:
```bash
xcodegen generate --spec project.yml --verbose
```

### Build Fails

**Error**: `BUILD FAILED`

**Check**:
1. Package dependencies resolved: `swift package resolve`
2. Framework search paths correct in `project.yml`
3. Code signing settings valid

**Debug**:
```bash
xcodebuild -project MyChatApp.xcodeproj -scheme MyChatApp build 2>&1 | grep error
```

### Simulator Not Found

**Error**: `Unable to find a destination matching the provided destination specifier`

**Solution**:
```bash
# List available simulators
xcrun simctl list devices available

# Use exact name from list
xcrun simctl boot "iPhone 17"
```

### App Won't Launch

**Error**: App installs but doesn't launch

**Check**:
1. Bundle identifier matches: `xcrun simctl launch booted <bundle-id>`
2. App is properly signed
3. Simulator is booted: `xcrun simctl list devices | grep Booted`

---

## Best Practices

### 1. Version Control

**Commit**:
- ✅ `project.yml`
- ✅ `Makefile`
- ✅ `Package.swift` (if used)
- ✅ Source code

**Don't commit**:
- ❌ `.xcodeproj` (generated)
- ❌ `build/` directory
- ❌ `.xcworkspace` (if generated)

### 2. Consistent Device Names

Use consistent simulator device names across team:

```makefile
SIMULATOR_DEVICE?=iPhone 17
```

### 3. Build Artifacts

Store build artifacts in `build/` directory (gitignored):

```makefile
-derivedDataPath build/DerivedData
```

### 4. Error Handling

Makefile targets should check for errors:

```makefile
if [ ! -d "$$APP_PATH" ]; then
    echo "❌ Build failed: app not found";
    exit 1;
fi
```

---

## Reference Examples

### Complete project.yml
See: `demo-apps/iOS/Simple/project.yml`

### Complete Makefile
See: `demo-apps/iOS/Simple/Makefile`

### Objective-C Example
See: `demo-apps/iOS/SimpleObjC/` for Objective-C specific patterns

---

## Next Steps

- **[Quick Start Guide](./quick-start.md)** - Build your first app
- **[Component Embedding Guide](./component-embedding.md)** - Learn component usage
- **[Developer Guide](./developer-guide.md)** - Comprehensive patterns

---

**Tip**: Always use `make generate` before building. Never edit `.xcodeproj` directly - edit `project.yml` instead.

