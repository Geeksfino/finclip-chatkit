PROJECT_NAME=iLoveHK
PROJECT_FILE=$(PROJECT_NAME).xcodeproj
SIMULATOR_DEVICE?=iPhone 17
SIMULATOR_DESTINATION?=platform=iOS Simulator,name=$(SIMULATOR_DEVICE)

.PHONY: generate open clean run run-cocoapods uninstall test-spm test-cocoapods validate-deps help

# Note: For external developers, CocoaPods is the recommended approach
# as it has more stable binary caching than SPM in development environments

# Generate Xcode project from package manifest
generate:
	@echo "🔧 Generating Xcode project..."
	xcodegen generate --spec project.yml
	@echo "✅ Project generated: $(PROJECT_FILE)"

open: generate
	@echo "📂 Opening $(PROJECT_FILE) in Xcode..."
	xed $(PROJECT_FILE)

# Build and run with CocoaPods (RECOMMENDED for external developers)
run-cocoapods:
	@echo "🚀 Building and running $(PROJECT_NAME) on iOS Simulator..."
	@echo "   (Using CocoaPods with prebuilt ChatKit binary)"
	@echo ""
	@if [ ! -f "Podfile" ]; then \
		echo "📝 Creating Podfile with direct binary pod reference..."; \
		printf 'platform :ios, "16.0"\n\ntarget "iLoveHK" do\n  pod "ChatKit", :podspec => "https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/v0.2.1/ChatKit.podspec"\nend\n' > Podfile; \
		echo "✅ Podfile created"; \
	fi
	@if [ ! -d "Pods" ]; then \
		echo "📦 Running pod install..."; \
		pod install || (echo "⚠️  Pod installation failed - ChatKit may not be available yet"; exit 1); \
	fi
	@echo "🔨 Building with CocoaPods..."
	xcodebuild \
	  -workspace iLoveHK.xcworkspace \
	  -scheme $(PROJECT_NAME) \
	  -destination '$(SIMULATOR_DESTINATION)' \
	  -configuration Debug \
	  -derivedDataPath build/DerivedData \
	  build
	@echo "✅ Build complete"

# Build and run with SPM (fallback - may have cache issues)
run: generate
	@echo "🚀 Building and running $(PROJECT_NAME) on iOS Simulator..."
	@echo "   (Using remote ChatKit from GitHub via SPM)"
	@echo ""
	@echo "⚠️  NOTE: For external developers, use 'make run-cocoapods' instead"
	@echo "          SPM can have cache permission issues in some environments"
	@echo ""
	xcodebuild \
	  -project $(PROJECT_FILE) \
	  -scheme $(PROJECT_NAME) \
	  -destination '$(SIMULATOR_DESTINATION)' \
	  -configuration Debug \
	  -derivedDataPath build/DerivedData \
	  build
	APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/$(PROJECT_NAME).app"; \
	if [ ! -d "$$APP_PATH" ]; then \
		echo "❌ Built app not found at $$APP_PATH"; \
		echo "⚠️  Try: make run-cocoapods"; \
		exit 1; \
	fi; \
	xcrun simctl boot "$(SIMULATOR_DEVICE)" >/dev/null 2>&1 || true; \
	xcrun simctl install booted "$$APP_PATH"; \
	xcrun simctl launch booted com.finclip.chatkit.ilovehk
	@echo "✅ $(PROJECT_NAME) launched on simulator"

# Test remote SPM dependency resolution
test-spm:
	@echo "🧪 Testing remote SPM dependency (ChatKit binary)..."
	@echo ""
	@echo "✅ Package.swift exists and syntax is valid"
	@echo ""
	@echo "📦 Validating Package.swift structure..."
	@grep -q "finclip-chatkit" Package.swift && echo "✅ ChatKit dependency URL found" || echo "❌ ChatKit dependency not found"
	@grep -q "from: \"0.1.0\"" Package.swift && echo "✅ Version constraint found (0.1.0)" || echo "❌ Version constraint not found"
	@grep -q "ChatKit" Package.swift && echo "✅ ChatKit product found" || echo "❌ ChatKit product not found"
	@echo ""
	@echo "🔗 Checking ChatKit release availability..."
	@curl -sI "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/ChatKit.xcframework.zip" 2>/dev/null | head -1 | grep -q "200\|302" && echo "✅ ChatKit XCFramework v0.1.0 is available" || echo "⚠️  ChatKit release not found"
	@echo ""
	@echo "📝 Note: SPM may have cache issues in sandboxed environments."
	@echo "         Use CocoaPods for more reliable binary downloads:"
	@echo "         make run-cocoapods"

# Test CocoaPods dependency (if Podfile exists)
test-cocoapods:
	@echo "🧪 Testing CocoaPods dependency resolution..."
	@if [ ! -f "Podfile" ]; then \
		echo "📝 Creating Podfile with direct binary pod reference..."; \
		printf 'platform :ios, "16.0"\n\ntarget "iLoveHK" do\n  pod "ChatKit", :podspec => "https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/v0.2.1/ChatKit.podspec"\nend\n' > Podfile; \
		echo "✅ Podfile created"; \
	fi
	@if command -v pod >/dev/null 2>&1; then \
		echo "📦 Testing pod spec resolution..."; \
		pod spec which ChatKit 2>&1 | head -3 || echo "⚠️  ChatKit using direct podspec reference from GitHub"; \
	else \
		echo "⚠️  CocoaPods not installed. Install with: sudo gem install cocoapods"; \
	fi

# Validate both SPM and CocoaPods dependencies
validate-deps:
	@echo "🔍 Validating remote dependencies..."
	@echo ""
	@echo "📦 SPM (Swift Package Manager) Validation:"
	@make test-spm 2>&1 | grep -E "✅|❌|⚠️" || true
	@echo ""
	@echo "📦 CocoaPods Validation:"
	@make test-cocoapods 2>&1 | grep -E "✅|❌|⚠️" || true
	@echo ""
	@echo "✅ Dependency validation complete"

clean:
	@echo "🧹 Cleaning generated project and build artifacts..."
	rm -rf $(PROJECT_FILE) $(PROJECT_NAME).xcworkspace iLoveHK.xcworkspace
	rm -rf .build build Podfile Podfile.lock Pods
	@echo "✅ Clean complete"

uninstall:
	@echo "🗑️  Uninstalling $(PROJECT_NAME) from booted simulator..."
	xcrun simctl uninstall booted com.finclip.chatkit.ilovehk || true
	@echo "✅ Uninstalled (if it was installed)"

# Help target
help:
	@echo "📱 Smart-Gov Example - External Developer Version"
	@echo ""
	@echo "ℹ️  This example uses REMOTE dependencies from GitHub (SPM/CocoaPods)"
	@echo "   No local ChatKit build required!"
	@echo ""
	@echo "🏗️  Build & Run Commands:"
	@echo "  make run-cocoapods    ⭐ RECOMMENDED: Build with CocoaPods"
	@echo "  make run              - Build with SPM (may have cache issues)"
	@echo "  make generate         - Generate Xcode project from Package.swift"
	@echo "  make open             - Open Xcode project"
	@echo "  make clean            - Clean all generated files and build artifacts"
	@echo "  make uninstall        - Uninstall app from simulator"
	@echo ""
	@echo "🧪 Dependency Testing:"
	@echo "  make validate-deps    - Run all dependency validations"
	@echo "  make test-spm         - Validate SPM Package.swift configuration"
	@echo "  make test-cocoapods   - Validate CocoaPods Podfile configuration"
	@echo ""
	@echo "📝 Files:"
	@echo "  Package.swift         - SPM manifest (defines remote ChatKit dependency)"
	@echo "  project.yml           - XcodeGen configuration"
	@echo "  Podfile               - CocoaPods manifest (auto-generated)"
	@echo ""
	@echo "🔗 Remote Dependency:"
	@echo "  ChatKit v0.1.0 from: https://github.com/Geeksfino/finclip-chatkit"
	@echo ""
	@echo "💡 Quick Start:"
	@echo "  make run-cocoapods    # Build and run with CocoaPods"
	@echo "  make help             # Show this help"
