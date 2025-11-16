PROJECT_NAME=SimpleObjC
PROJECT_FILE=$(PROJECT_NAME).xcodeproj
XCODEGEN=which xcodegen
SIMULATOR_DEVICE?=iPhone 17
SIMULATOR_OS?=latest
SIMULATOR_DESTINATION?=platform=iOS Simulator,name=$(SIMULATOR_DEVICE),OS=$(SIMULATOR_OS)

.PHONY: spm-generate spm-open spm-run clean deep-clean pod-project pod-install pod-build pod-run pod-clean

help:
	@echo "SimpleObjC Example Build System"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "XcodeGen (Direct Frameworks via SPM):"
	@echo "  spm-generate       - Generate Xcode project using XcodeGen"
	@echo "  spm-open           - Generate and open Xcode project"
	@echo "  spm-run             - Build and run in simulator"
	@echo ""
	@echo "CocoaPods (Bundled Distribution):"
	@echo "  pod-install         - Install CocoaPods dependencies"
	@echo "  pod-build           - Build using CocoaPods workspace"
	@echo "  pod-run             - Build and run using CocoaPods workspace"
	@echo "  pod-clean           - Clean CocoaPods artifacts"
	@echo ""
	@echo "Utilities:"
	@echo "  clean               - Clean build artifacts"
	@echo "  deep-clean          - Clean all artifacts including CocoaPods"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - XcodeGen must be installed: brew install xcodegen"
	@echo "  - CocoaPods must be installed: sudo gem install cocoapods"

spm-generate:
	@if ! command -v xcodegen >/dev/null 2>&1; then \
		echo "❌ XcodeGen not installed. Install with 'brew install xcodegen'."; \
		exit 1; \
	fi
	@echo "🔧 Generating Xcode project..."
	xcodegen generate --spec project.yml
	@echo "✅ Project generated: $(PROJECT_FILE)"

spm-open: spm-generate
	@echo "📂 Opening $(PROJECT_FILE)..."
	xed "$(PROJECT_FILE)"

spm-run: spm-generate
	@echo "🚀 Building and running $(PROJECT_NAME) on iOS simulator..."
	@echo "📱 Finding simulator UUID for $(SIMULATOR_DEVICE)..."
	SIM_UUID=$$(xcrun simctl list devices available | grep "$(SIMULATOR_DEVICE) (" | head -n 1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/'); \
	if [ -z "$$SIM_UUID" ]; then \
		echo "❌ No available simulator found matching '$(SIMULATOR_DEVICE)'"; \
		echo "💡 Run 'xcrun simctl list devices available' to see available simulators"; \
		exit 1; \
	fi; \
	echo "✓ Using simulator: $$SIM_UUID"; \
	xcodebuild \
	  -project "$(PROJECT_FILE)" \
	  -scheme "$(PROJECT_NAME)" \
	  -destination "platform=iOS Simulator,id=$$SIM_UUID" \
	  -configuration Debug \
	  -derivedDataPath build/DerivedData \
	  build; \
	APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/$(PROJECT_NAME).app"; \
	if [ ! -d "$$APP_PATH" ]; then \
		echo "❌ Built app not found at $$APP_PATH"; \
		exit 1; \
	fi; \
	xcrun simctl boot "$$SIM_UUID" >/dev/null 2>&1 || true; \
	xcrun simctl install "$$SIM_UUID" "$$APP_PATH"; \
	xcrun simctl launch "$$SIM_UUID" com.finclip.chatkit.simpleobjc
	@echo "✅ $(PROJECT_NAME) launched on simulator"

clean:
	@echo "🧹 Cleaning generated project and local build outputs..."
	rm -rf "$(PROJECT_FILE)" "$(PROJECT_NAME).xcworkspace"
	rm -rf build
	@echo "✅ Clean complete"

deep-clean: clean pod-clean
	@echo "🧼 Removing simulator-installed app (if any)..."
	- xcrun simctl uninstall booted com.finclip.chatkit.simpleobjc >/dev/null 2>&1 || true
	@echo "✅ Deep clean complete"

# CocoaPods targets for bundled distribution
pod-project:
	@echo "📐 Generating Xcode project for CocoaPods..."
	@if ! command -v xcodegen >/dev/null 2>&1; then \
		echo "❌ XcodeGen not found. Install with: brew install xcodegen"; \
		exit 1; \
	fi
	@# Use CocoaPods-specific project.yml (no framework dependencies)
	xcodegen generate --spec project-cocoapods.yml
	@echo "✅ Project generated for CocoaPods"

pod-install: pod-project
	@echo "📦 Installing CocoaPods dependencies..."
	@if ! command -v pod >/dev/null 2>&1; then \
		echo "❌ CocoaPods not found. Install with: sudo gem install cocoapods"; \
		exit 1; \
	fi
	@# Workaround for SSL issues: download podspec locally first, then use it
	@echo "📥 Downloading podspec from GitHub (workaround for SSL issues)..."
	@PODSPEC_URL="https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/main/FinClipChatKit.podspec"; \
	LOCAL_PODSPEC="FinClipChatKit-remote.podspec"; \
	if curl -f -s -o "$$LOCAL_PODSPEC" "$$PODSPEC_URL"; then \
		echo "✅ Podspec downloaded to $$LOCAL_PODSPEC"; \
		echo "📝 Temporarily updating Podfile to use local podspec..."; \
		cp Podfile Podfile.orig; \
		sed "s|https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/main/FinClipChatKit.podspec|$$LOCAL_PODSPEC|" Podfile.orig > Podfile; \
		pod install; \
		EXIT_CODE=$$?; \
		mv Podfile.orig Podfile; \
		if [ $$EXIT_CODE -ne 0 ]; then exit $$EXIT_CODE; fi; \
	else \
		echo "⚠️  Failed to download podspec, trying direct remote fetch..."; \
		pod install || (echo "❌ SSL error detected. Try: brew install openssl && gem install openssl"; exit 1); \
	fi
	@echo "✅ CocoaPods dependencies installed"

pod-build: pod-install
	@echo "🔨 Building $(PROJECT_NAME) with CocoaPods..."
	@if [ ! -d "$(PROJECT_NAME).xcworkspace" ]; then \
		echo "❌ Workspace not found. Run 'make pod-install' first."; \
		exit 1; \
	fi
	xcodebuild \
		-workspace $(PROJECT_NAME).xcworkspace \
		-scheme $(PROJECT_NAME) \
		-destination '$(SIMULATOR_DESTINATION)' \
		-configuration Debug \
		-derivedDataPath build/DerivedData \
		build \
		| xcpretty || true
	@echo "✅ Build complete"

pod-run: pod-install
	@echo "🚀 Building and running $(PROJECT_NAME) with CocoaPods..."
	@if [ ! -d "$(PROJECT_NAME).xcworkspace" ]; then \
		echo "❌ Workspace not found. Run 'make pod-install' first."; \
		exit 1; \
	fi
	SIM_UUID=$$(xcrun simctl list devices available | grep "$(SIMULATOR_DEVICE) (" | head -n 1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/'); \
	if [ -z "$$SIM_UUID" ]; then \
		echo "❌ No available simulator found matching '$(SIMULATOR_DEVICE)'"; \
		echo "💡 Run 'xcrun simctl list devices available' to see available simulators"; \
		exit 1; \
	fi; \
	echo "✓ Using simulator: $$SIM_UUID"; \
	xcodebuild \
		-workspace $(PROJECT_NAME).xcworkspace \
		-scheme $(PROJECT_NAME) \
		-destination "platform=iOS Simulator,id=$$SIM_UUID" \
		-configuration Debug \
		-derivedDataPath build/DerivedData \
		build; \
	APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/$(PROJECT_NAME).app"; \
	if [ ! -d "$$APP_PATH" ]; then \
		echo "❌ Built app not found at $$APP_PATH"; \
		exit 1; \
	fi; \
	xcrun simctl boot "$$SIM_UUID" >/dev/null 2>&1 || true; \
	xcrun simctl install "$$SIM_UUID" "$$APP_PATH"; \
	xcrun simctl launch "$$SIM_UUID" com.finclip.chatkit.simpleobjc
	@echo "✅ $(PROJECT_NAME) launched on simulator"

pod-clean:
	@echo "🧹 Cleaning CocoaPods artifacts..."
	rm -rf Pods
	rm -rf $(PROJECT_NAME).xcworkspace
	rm -rf Podfile.lock
	rm -f FinClipChatKit-remote.podspec
	rm -f Podfile.orig
	@echo "✅ CocoaPods clean complete"

