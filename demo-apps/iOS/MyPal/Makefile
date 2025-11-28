PROJECT_NAME=MyPal
PROJECT_FILE=$(PROJECT_NAME).xcodeproj
XCODEGEN=which xcodegen
SIMULATOR_DEVICE?=iPhone 17
SIMULATOR_OS?=latest
SIMULATOR_DESTINATION?=platform=iOS Simulator,name=$(SIMULATOR_DEVICE),OS=$(SIMULATOR_OS)

.PHONY: generate open clean deep-clean run download-model download-phi3 download-all-models download-gemma-task

generate:
	@if ! command -v xcodegen >/dev/null 2>&1; then \
		echo "❌ XcodeGen not installed. Install with 'brew install xcodegen'."; \
		exit 1; \
	fi
	@echo "🔧 Generating Xcode project..."
	xcodegen generate --spec project.yml
	@echo "✅ Project generated: $(PROJECT_FILE)"
	@echo ""
	@if [ -f "Podfile" ]; then \
		echo "📦 Installing CocoaPods dependencies..."; \
		if ! command -v pod >/dev/null 2>&1; then \
			echo "⚠️  CocoaPods not installed. Install with 'sudo gem install cocoapods'."; \
			echo "   Skipping pod install..."; \
		else \
			pod install; \
			echo "✅ CocoaPods dependencies installed"; \
		fi; \
	else \
		echo "ℹ️  No Podfile found, skipping pod install"; \
	fi

open: generate
	@if [ -d "$(PROJECT_NAME).xcworkspace" ]; then \
		echo "📂 Opening $(PROJECT_NAME).xcworkspace..."; \
		xed "$(PROJECT_NAME).xcworkspace"; \
	else \
		echo "📂 Opening $(PROJECT_FILE)..."; \
		xed "$(PROJECT_FILE)"; \
	fi

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
	if [ -d "$(PROJECT_NAME).xcworkspace" ]; then \
		xcodebuild \
		  -workspace "$(PROJECT_NAME).xcworkspace" \
		  -scheme "$(PROJECT_NAME)" \
		  -destination "platform=iOS Simulator,id=$$SIM_UUID" \
		  -configuration Debug \
		  -derivedDataPath build/DerivedData \
		  build; \
	else \
		xcodebuild \
		  -project "$(PROJECT_FILE)" \
		  -scheme "$(PROJECT_NAME)" \
		  -destination "platform=iOS Simulator,id=$$SIM_UUID" \
		  -configuration Debug \
		  -derivedDataPath build/DerivedData \
		  build; \
	fi; \
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
	rm -rf Pods
	rm -f Podfile.lock
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
	@echo "✅ Gemma model download complete!"
	@echo "💡 Run 'make generate' to update Xcode project with model files"

download-phi3:
	@echo "📥 Downloading Phi-3 Mini 4k Instruct model files..."
	@if [ ! -f "scripts/download-phi3-mini.sh" ]; then \
		echo "❌ Download script not found at scripts/download-phi3-mini.sh"; \
		exit 1; \
	fi
	@chmod +x scripts/download-phi3-mini.sh
	@./scripts/download-phi3-mini.sh
	@echo ""
	@echo "✅ Phi-3 model download complete!"
	@echo "💡 Run 'make generate' to update Xcode project with model files"
	@echo "🧪 Test with: cd Test && ./run_gemma_test.sh -d ../App/Models/phi-3-mini-4k-instruct-4bit -p 'Hello' -n 20"

download-gemma-task:
	@echo "📥 Downloading Gemma-3 270M MediaPipe model (.task format) from Kaggle..."
	@if [ ! -f "scripts/download-gemma-task.sh" ]; then \
		echo "❌ Download script not found at scripts/download-gemma-task.sh"; \
		exit 1; \
	fi
	@chmod +x scripts/download-gemma-task.sh
	@./scripts/download-gemma-task.sh
	@echo ""
	@echo "✅ Gemma MediaPipe model download complete!"
	@echo "💡 Run 'make generate' to update Xcode project with model file"

download-all-models:
	@echo "📥 Downloading all supported models..."
	@echo ""
	@$(MAKE) download-model
	@echo ""
	@$(MAKE) download-phi3
	@echo ""
	@echo "✅ All models downloaded!"
	@echo "💡 Run 'make generate' to update Xcode project with all model files"

