PROJECT_NAME=MyPal
PROJECT_FILE=$(PROJECT_NAME).xcodeproj
XCODEGEN=which xcodegen
SIMULATOR_DEVICE?=iPhone 17
SIMULATOR_OS?=latest
SIMULATOR_DESTINATION?=platform=iOS Simulator,name=$(SIMULATOR_DEVICE),OS=$(SIMULATOR_OS)

.PHONY: generate open clean deep-clean run download-model

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
	xcrun simctl launch "$$SIM_UUID" com.finclip.chatkit.mypal
	@echo "✅ $(PROJECT_NAME) launched on simulator"

clean:
	@echo "🧹 Cleaning generated project and local build outputs..."
	rm -rf "$(PROJECT_FILE)" "$(PROJECT_NAME).xcworkspace"
	rm -rf build
	@echo "✅ Clean complete"

deep-clean: clean
	@echo "🧼 Removing simulator-installed app (if any)..."
	- xcrun simctl uninstall booted com.finclip.chatkit.mypal >/dev/null 2>&1 || true
	@echo "✅ Deep clean complete"

download-model:
	@echo "📥 Downloading Gemma 270M model files..."
	@if [ ! -f "scripts/download-model.sh" ]; then \
		echo "❌ Download script not found at scripts/download-model.sh"; \
		exit 1; \
	fi
	@chmod +x scripts/download-model.sh
	@./scripts/download-model.sh
	@echo ""
	@echo "✅ Model download complete!"
	@echo "💡 Run 'make generate' to update Xcode project with model files"

