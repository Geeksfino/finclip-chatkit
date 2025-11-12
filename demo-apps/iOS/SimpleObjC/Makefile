PROJECT_NAME=SimpleObjC
PROJECT_FILE=$(PROJECT_NAME).xcodeproj
XCODEGEN=which xcodegen
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
	xcrun simctl launch booted com.finclip.chatkit.simpleobjc
	@echo "✅ $(PROJECT_NAME) launched on simulator"

clean:
	@echo "🧹 Cleaning generated project and local build outputs..."
	rm -rf "$(PROJECT_FILE)" "$(PROJECT_NAME).xcworkspace"
	rm -rf build
	@echo "✅ Clean complete"

deep-clean: clean
	@echo "🧼 Removing simulator-installed app (if any)..."
	- xcrun simctl uninstall booted com.finclip.chatkit.simpleobjc >/dev/null 2>&1 || true
	@echo "✅ Deep clean complete"

