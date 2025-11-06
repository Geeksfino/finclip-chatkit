.PHONY: all clean build run test project help

# Default target
all: build

# Generate Xcode project from project.yml using XcodeGen
project:
	@echo "Generating Xcode project..."
	@which xcodegen > /dev/null || (echo "Error: xcodegen not found. Install with: brew install xcodegen" && exit 1)
	xcodegen generate

# Build the project
build: project
	@echo "Building AI-Bank-OC..."
	xcodebuild -project AI-Bank-OC.xcodeproj \
		-scheme AI-Bank-OC \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-configuration Debug \
		build

# Run on simulator
run: build
	@echo "Running AI-Bank-OC on simulator..."
	@DEVICE_ID=$$(xcrun simctl list devices | grep "iPhone 17" | grep -v unavailable | head -n 1 | grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})"); \
	if [ -z "$$DEVICE_ID" ]; then \
		echo "Error: iPhone 17 simulator not found"; \
		exit 1; \
	fi; \
	APP_PATH=$$(find ~/Library/Developer/Xcode/DerivedData -name "AI-Bank-OC.app" -path "*/Debug-iphonesimulator/*" | head -n 1); \
	if [ -z "$$APP_PATH" ]; then \
		echo "Error: Could not find AI-Bank-OC.app"; \
		exit 1; \
	fi; \
	echo "Installing app from: $$APP_PATH"; \
	xcrun simctl boot "$$DEVICE_ID" 2>/dev/null || true; \
	xcrun simctl install "$$DEVICE_ID" "$$APP_PATH"; \
	xcrun simctl launch --console "$$DEVICE_ID" com.finclip.ai-bank-oc

# Run tests
test: project
	@echo "Running tests..."
	xcodebuild test -project AI-Bank-OC.xcodeproj \
		-scheme AI-Bank-OC \
		-destination 'platform=iOS Simulator,name=iPhone 17'

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf build/
	rm -rf DerivedData/
	rm -rf .build/
	rm -rf *.xcodeproj
	xcodebuild clean || true

# Install dependencies
deps:
	@echo "Dependencies are managed via Swift Package Manager"
	@echo "They will be automatically resolved when building"

# Help
help:
	@echo "AI-Bank-OC Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make project    - Generate Xcode project from project.yml"
	@echo "  make build      - Build the application"
	@echo "  make run        - Run the application on simulator"
	@echo "  make test       - Run tests"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make deps       - Show dependency information"
	@echo "  make help       - Show this help message"
	@echo ""
	@echo "Requirements:"
	@echo "  - Xcode 16.4 or later"
	@echo "  - XcodeGen (install with: brew install xcodegen)"
	@echo "  - iOS 16.0 SDK or later"


