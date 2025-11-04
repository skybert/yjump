# yjump Makefile
# Swift window switcher for macOS

APP_NAME = yjump
SRC_DIR = src
MAN_DIR = man
CONF_DIR = conf
BUILD_DIR = build
INSTALL_PREFIX = $(HOME)/.local
BIN_DIR = $(INSTALL_PREFIX)/bin
MAN_INSTALL_DIR = $(INSTALL_PREFIX)/share/man/man1
CONF_INSTALL_DIR = $(HOME)/.config/yjump
APP_BUNDLE = $(APP_NAME).app
INSTALL_APP_DIR = /Applications

SWIFT_FLAGS = -O
SOURCES = $(SRC_DIR)/cli.swift $(SRC_DIR)/conf.swift $(SRC_DIR)/gui.swift $(SRC_DIR)/main.swift

# Get version from git
GIT_VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Test settings
TEST_DIR = tests
TEST_SOURCES = $(wildcard $(TEST_DIR)/*Tests.swift)
TEST_BUILD_DIR = $(BUILD_DIR)/tests

# Formatter
SWIFTFORMAT := $(shell command -v swiftformat 2> /dev/null || echo "$(HOME)/.local/bin/swiftformat")

.PHONY: all build clean install uninstall test run help format format-check install-formatter

all: build

# Format code before building
build: format $(BUILD_DIR)/$(APP_NAME)

$(BUILD_DIR)/$(APP_NAME): $(SOURCES) $(SRC_DIR)/cli.swift
	@echo "Building $(APP_NAME) version $(GIT_VERSION)..."
	@mkdir -p $(BUILD_DIR)
	@# Create a temporary version file
	@sed 's/GIT_VERSION_PLACEHOLDER/$(GIT_VERSION)/' $(SRC_DIR)/cli.swift > $(BUILD_DIR)/cli_versioned.swift.tmp
	@mv $(BUILD_DIR)/cli_versioned.swift.tmp $(BUILD_DIR)/cli_versioned.swift
	@swiftc $(SWIFT_FLAGS) $(BUILD_DIR)/cli_versioned.swift $(SRC_DIR)/conf.swift $(SRC_DIR)/gui.swift $(SRC_DIR)/main.swift -o $(BUILD_DIR)/$(APP_NAME)
	@rm -f $(BUILD_DIR)/cli_versioned.swift
	@echo "Build complete: $(BUILD_DIR)/$(APP_NAME)"

# Run the application
run: build
	@echo "Running $(APP_NAME)..."
	@$(BUILD_DIR)/$(APP_NAME)

# Install the application and man page
install: build
	@echo "Installing $(APP_NAME)..."
	@# Create app bundle structure
	@mkdir -p $(BUILD_DIR)/$(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(BUILD_DIR)/$(APP_BUNDLE)/Contents/Resources
	@# Copy binary to app bundle
	@cp $(BUILD_DIR)/$(APP_NAME) $(BUILD_DIR)/$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@# Create Info.plist from template
	@sed 's/GIT_VERSION_PLACEHOLDER/$(GIT_VERSION)/' $(SRC_DIR)/yjump.plist > $(BUILD_DIR)/$(APP_BUNDLE)/Contents/Info.plist
	@# Install app bundle to /Applications
	@rm -rf $(INSTALL_APP_DIR)/$(APP_BUNDLE)
	@cp -R $(BUILD_DIR)/$(APP_BUNDLE) $(INSTALL_APP_DIR)/$(APP_BUNDLE)
	@# Also install CLI binary and man page
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(MAN_INSTALL_DIR)
	@mkdir -p $(CONF_INSTALL_DIR)
	@install -m 755 $(BUILD_DIR)/$(APP_NAME) $(BIN_DIR)/$(APP_NAME)
	@# Process man page to replace AUTHORS placeholder
	@if [ -f AUTHORS ]; then \
		sed "s/AUTHORS_FILE_CONTENTS/$$(sed 's/\//\\\//g; s/&/\\&/g' AUTHORS | tr '\n' '|' | sed 's/|$$//' | sed 's/|/\\n.br\\n/g')/" $(MAN_DIR)/$(APP_NAME).1 > $(MAN_INSTALL_DIR)/$(APP_NAME).1; \
	else \
		cp $(MAN_DIR)/$(APP_NAME).1 $(MAN_INSTALL_DIR)/$(APP_NAME).1; \
	fi
	@chmod 644 $(MAN_INSTALL_DIR)/$(APP_NAME).1
	@if [ ! -f $(CONF_INSTALL_DIR)/$(APP_NAME).conf ]; then \
		install -m 644 $(CONF_DIR)/$(APP_NAME).conf $(CONF_INSTALL_DIR)/$(APP_NAME).conf; \
		echo "Installed config file to $(CONF_INSTALL_DIR)/$(APP_NAME).conf"; \
	else \
		echo "Config file already exists at $(CONF_INSTALL_DIR)/$(APP_NAME).conf (not overwriting)"; \
	fi
	@echo "Installed $(APP_NAME).app to $(INSTALL_APP_DIR)/$(APP_BUNDLE)"
	@echo "Installed $(APP_NAME) CLI to $(BIN_DIR)/$(APP_NAME)"
	@echo "Installed man page to $(MAN_INSTALL_DIR)/$(APP_NAME).1"
	@echo ""
	@echo "Installation complete!"
	@echo "Run '$(APP_NAME)' from terminal or launch from Applications folder"
	@echo "Run 'man $(APP_NAME)' to view the manual"
	@echo "Edit $(CONF_INSTALL_DIR)/$(APP_NAME).conf to customize appearance"

# Uninstall the application
uninstall:
	@echo "Uninstalling $(APP_NAME)..."
	@rm -rf $(INSTALL_APP_DIR)/$(APP_BUNDLE)
	@rm -f $(BIN_DIR)/$(APP_NAME)
	@rm -f $(MAN_INSTALL_DIR)/$(APP_NAME).1
	@echo "Uninstalled $(APP_NAME)"
	@echo "Note: Config file at $(CONF_INSTALL_DIR)/$(APP_NAME).conf was not removed"

# Run tests (placeholder for future tests)
test:
	@echo "Running tests..."
	@if [ -z "$(TEST_SOURCES)" ]; then \
		echo "No tests defined yet"; \
	else \
		mkdir -p $(TEST_BUILD_DIR); \
		echo "Building and running ConfigTests..."; \
		swift tests/ConfigTests.swift && \
		echo "Building and running FuzzyMatchTests..."; \
		swift tests/FuzzyMatchTests.swift && \
		echo "Building and running WindowInfoTests..."; \
		swift tests/WindowInfoTests.swift && \
		echo ""; \
		echo "All tests passed!"; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "Clean complete"

# Display help
help:
	@echo "yjump - Fast window switcher for macOS"
	@echo ""
	@echo "Available targets:"
	@echo "  make build           - Format and build the application (default)"
	@echo "  make run             - Build and run the application"
	@echo "  make format          - Format Swift source files"
	@echo "  make format-check    - Check if source files need formatting"
	@echo "  make install         - Install to $(BIN_DIR)"
	@echo "  make install-formatter - Install SwiftFormat tool"
	@echo "  make uninstall       - Remove installed files"
	@echo "  make test            - Run tests"
	@echo "  make clean           - Remove build artifacts"
	@echo "  make help            - Show this help message"

# Format Swift source code
format:
	@if [ -x "$(SWIFTFORMAT)" ]; then \
		echo "Formatting Swift source files..."; \
		$(SWIFTFORMAT) $(SRC_DIR) $(TEST_DIR) --config .swiftformat 2>/dev/null || true; \
	else \
		echo "⚠️  SwiftFormat not found. Skipping formatting."; \
		echo "   Run 'make install-formatter' to install SwiftFormat"; \
	fi

# Check if formatting is needed (for CI)
format-check:
	@if [ -x "$(SWIFTFORMAT)" ]; then \
		echo "Checking Swift code formatting..."; \
		$(SWIFTFORMAT) $(SRC_DIR) $(TEST_DIR) --config .swiftformat --lint || \
		(echo "❌ Code formatting check failed. Run 'make format' to fix." && exit 1); \
		echo "✅ Code formatting is correct"; \
	else \
		echo "⚠️  SwiftFormat not found. Skipping format check."; \
		echo "   Run 'make install-formatter' to install SwiftFormat"; \
	fi

# Install SwiftFormat
install-formatter:
	@echo "Installing SwiftFormat..."
	@bash bin/install-swiftformat.sh
