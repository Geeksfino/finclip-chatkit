# Smart-Gov Example: Remote Dependency Testing

This directory contains the **iLoveHK** demo application configured to test both **remote SPM (Swift Package Manager)** and **CocoaPods** dependencies for the ChatKit framework.

## Overview

The Smart-Gov example has been enhanced with:
- **Package.swift**: Swift Package Manager manifest for testing remote binary dependency resolution
- **project.yml**: XcodeGen configuration for the native iOS app
- **Makefile**: Comprehensive build and testing targets

## Quick Start

### Run All Dependency Validations

```bash
make validate-deps
```

This will test both SPM and CocoaPods dependency resolution:

```
🔍 Validating remote dependencies...

📦 SPM (Swift Package Manager) Validation:
✅ Package.swift exists and syntax is valid
✅ ChatKit dependency URL found
✅ Version constraint found (0.1.0)
✅ ChatKit product found
✅ ChatKit XCFramework v0.1.0 is available

📦 CocoaPods Validation:
✅ Dependency validation complete
```

### Test Individual Package Managers

#### SPM (Swift Package Manager)

```bash
make test-spm
```

**What it tests:**
- ✅ Package.swift syntax and structure
- ✅ ChatKit remote dependency URL configuration
- ✅ Version constraint (`from: "0.1.0"`)
- ✅ ChatKit product availability
- ✅ GitHub release availability for ChatKit.xcframework.zip

**Expected Output:**
```
🧪 Testing remote SPM dependency (ChatKit binary)...

✅ Package.swift exists and syntax is valid

📦 Validating Package.swift structure...
✅ ChatKit dependency URL found
✅ Version constraint found (0.1.0)
✅ ChatKit product found

🔗 Checking ChatKit release availability...
✅ ChatKit XCFramework v0.1.0 is available
```

#### CocoaPods

```bash
make test-cocoapods
```

**What it tests:**
- ✅ CocoaPods installation
- ✅ Podfile structure
- ✅ Pod repo configuration
- ✅ ChatKit pod specification availability

## Available Make Targets

### Build & Run

| Target | Description |
|--------|-------------|
| `make generate` | Generate Xcode project from `project.yml` using XcodeGen |
| `make open` | Open the generated Xcode project |
| `make run` | Build and run on iOS Simulator (requires local ChatKit.xcframework) |
| `make clean` | Clean build artifacts and generated files |
| `make uninstall` | Remove app from simulator |

### Dependency Testing

| Target | Description |
|--------|-------------|
| `make test-spm` | Validate remote SPM dependency resolution |
| `make test-cocoapods` | Validate CocoaPods dependency resolution |
| `make validate-deps` | Run all dependency validations |

### Information

| Target | Description |
|--------|-------------|
| `make help` | Display help with all available commands |

## Project Structure

```
Smart-Gov/
├── App/                          # Application source code
│   ├── App/                      # Main app entry point
│   ├── Coordinators/             # Conversation coordination logic
│   ├── Models/                   # Data models
│   ├── Network/                  # Network adapters and mocks
│   ├── ViewControllers/          # UI view controllers
│   └── Resources/                # Assets, videos, fixtures
├── Package.swift                 # ✨ NEW: SPM manifest for remote testing
├── project.yml                   # XcodeGen project configuration
├── Makefile                      # Build and test targets
└── README-REMOTE-DEPS.md         # This file
```

## Remote Dependency Configuration

### SPM (Package.swift)

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "iLoveHK-App",
    dependencies: [
        // ChatKit with remote binary XCFramework
        .package(
            url: "https://github.com/Geeksfino/finclip-chatkit.git",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "iLoveHK-App",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit")
            ],
            // ...
        )
    ]
)
```

**Features:**
- Points to the remote ChatKit repository
- Uses semantic versioning (`from: "0.1.0"`)
- Automatically resolves binary XCFramework from GitHub releases
- Supports both iOS and macOS targets (configured in project.yml)

### CocoaPods (Podfile - auto-generated)

```ruby
platform :ios, '16.0'

target 'iLoveHK' do
  pod 'ChatKit', '~> 0.1.0'
  
  # Required dependencies (bundled in ChatKit)
  pod 'NeuronKit'
  pod 'ConvoUI'
  pod 'SandboxSDK'
  pod 'convstore'
end
```

**Features:**
- Flexible version constraint (`~> 0.1.0`)
- Auto-generates when running `make test-cocoapods`
- Specifies all bundled dependencies

## Dependency Resolution Flow

### SPM Flow

1. **Package Resolution**
   ```bash
   swift package resolve --package-path .
   ```
   - Reads Package.swift
   - Resolves `finclip-chatkit` dependency
   - Downloads Package.swift from remote repo

2. **Binary Artifact Download**
   - SPM queries GitHub releases for download URLs
   - Matches binary target checksum
   - Downloads ChatKit.xcframework.zip from:
     ```
     https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/ChatKit.xcframework.zip
     ```

3. **Build Integration**
   - XCBuild links ChatKit.xcframework
   - Nested frameworks (NeuronKit, ConvoUI, etc.) are embedded
   - Code signing is applied

### CocoaPods Flow

1. **Pod Resolution**
   ```bash
   pod install
   ```
   - Reads Podfile
   - Queries CocoaPods pod specs
   - Resolves dependencies

2. **Binary Download**
   - Downloads ChatKit.xcframework
   - Downloads NeuronKit, ConvoUI, SandboxSDK, convstore
   - Places in `Pods/` directory

3. **Workspace Integration**
   - Creates `.xcworkspace` with app and Pods targets
   - Configures build settings for framework linking

## Troubleshooting

### SPM Issues

**"Cannot find ChatKit in scope"**
- Ensure Package.swift has correct dependency: `finclip-chatkit`
- Verify the package is published to GitHub
- Run: `swift package update --package-path .`

**"Invalid checksum"**
- The checksum in Package.swift must match the actual binary
- Update checksum after new releases:
  ```bash
  swift package compute-checksum ChatKit.xcframework.zip
  ```

### CocoaPods Issues

**"The dependency mapping for target iLoveHK is missing"**
- Run: `pod install` to generate Pods workspace
- Ensure Podfile syntax is correct

**"Cannot find pod ChatKit"**
- CocoaPods may not have ChatKit published yet
- Ensure `pod repo update` completes successfully

## Validation Results

### Latest Run ✅

```
🔍 Validating remote dependencies...

📦 SPM (Swift Package Manager) Validation:
✅ Package.swift exists and syntax is valid
✅ ChatKit dependency URL found
✅ Version constraint found (0.1.0)
✅ ChatKit product found
✅ ChatKit XCFramework v0.1.0 is available

📦 CocoaPods Validation:
✅ Dependency validation complete
```

## Next Steps

1. **Test SPM Resolution**
   ```bash
   make test-spm
   ```

2. **Test CocoaPods Resolution**
   ```bash
   make test-cocoapods
   ```

3. **Build Local App** (requires local ChatKit.xcframework)
   ```bash
   make run
   ```

4. **For Full Integration Testing**
   - Update to use remote dependencies in project.yml
   - Configure SPM integration in Xcode project
   - Test on device and simulator

## Files Modified/Added

- ✨ **Package.swift** - NEW: SPM manifest for remote binary dependency testing
- 📝 **Makefile** - ENHANCED: Added `test-spm`, `test-cocoapods`, `validate-deps` targets
- 📄 **README-REMOTE-DEPS.md** - NEW: This documentation

## Related Documentation

- [ChatKit Repository](https://github.com/Geeksfino/finclip-chatkit)
- [Swift Package Manager Binary Targets](https://developer.apple.com/documentation/swift_packages/offering_binary_targets)
- [CocoaPods Official Docs](https://guides.cocoapods.org/)

## References

- **ChatKit v0.1.0**: https://github.com/Geeksfino/finclip-chatkit/releases/tag/v0.1.0
- **Checksum**: `4c05da179daf5283b16f4b5617ee4f349d41d83b357938fa9373bf754c883782`
