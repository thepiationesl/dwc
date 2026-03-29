.PHONY: all build clean test

BINARY_NAME=img-transfer
VERSION=2.0.0
BUILD_DIR=./dist
SOURCE_DIR=.
MAIN_SOURCE=$(SOURCE_DIR)/main.py

# Default target
all: build

# Build the binary
build: $(BUILD_DIR)/$(BINARY_NAME)

# Build using PyInstaller
$(BUILD_DIR)/$(BINARY_NAME): $(MAIN_SOURCE)
	@echo "Building $(BINARY_NAME) v$(VERSION)..."
	@mkdir -p $(BUILD_DIR)
	@pyinstaller --onefile --name $(BINARY_NAME) $(MAIN_SOURCE)
	@mv ./dist/$(BINARY_NAME) $(BUILD_DIR)/
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

# Test the binary
test: build
	@$(BUILD_DIR)/$(BINARY_NAME) version

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf ./build ./dist ./__pycache__ ./*.spec
	@rm -rf $(SOURCE_DIR)/build $(SOURCE_DIR)/dist $(SOURCE_DIR)/__pycache__ $(SOURCE_DIR)/*.spec
	@echo "Clean complete"

# Install dependencies (for development)
dev-install:
	@pip install --break-system-packages pyinstaller

# Help
help:
	@echo "Available targets:"
	@echo "  all        - Build the binary (default)"
	@echo "  build      - Build the binary using PyInstaller"
	@echo "  test       - Test the built binary"
	@echo "  clean      - Remove build artifacts"
	@echo "  dev-install - Install development dependencies"
	@echo "  help       - Show this help"