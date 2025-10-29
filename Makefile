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

SWIFT_FLAGS = -O
SOURCES = $(SRC_DIR)/cli.swift $(SRC_DIR)/conf.swift $(SRC_DIR)/main.swift

# Get version from git
GIT_VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Test settings
TEST_DIR = tests
TEST_SOURCES = $(wildcard $(TEST_DIR)/*Tests.swift)
TEST_BUILD_DIR = $(BUILD_DIR)/tests

.PHONY: all build clean install uninstall test run help

all: build

# Build the application
build: $(BUILD_DIR)/$(APP_NAME)

$(BUILD_DIR)/$(APP_NAME): $(SOURCES) $(SRC_DIR)/cli.swift
	@echo "Building $(APP_NAME) version $(GIT_VERSION)..."
	@mkdir -p $(BUILD_DIR)
	@# Create a temporary version file
	@sed 's/GIT_VERSION_PLACEHOLDER/$(GIT_VERSION)/' $(SRC_DIR)/cli.swift > $(BUILD_DIR)/cli_versioned.swift.tmp
	@mv $(BUILD_DIR)/cli_versioned.swift.tmp $(BUILD_DIR)/cli_versioned.swift
	@swiftc $(SWIFT_FLAGS) $(BUILD_DIR)/cli_versioned.swift $(SRC_DIR)/conf.swift $(SRC_DIR)/main.swift -o $(BUILD_DIR)/$(APP_NAME)
	@rm -f $(BUILD_DIR)/cli_versioned.swift
	@echo "Build complete: $(BUILD_DIR)/$(APP_NAME)"

# Run the application
run: build
	@echo "Running $(APP_NAME)..."
	@$(BUILD_DIR)/$(APP_NAME)

# Install the application and man page
install: build
	@echo "Installing $(APP_NAME)..."
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(MAN_INSTALL_DIR)
	@mkdir -p $(CONF_INSTALL_DIR)
	@install -m 755 $(BUILD_DIR)/$(APP_NAME) $(BIN_DIR)/$(APP_NAME)
	@install -m 644 $(MAN_DIR)/$(APP_NAME).1 $(MAN_INSTALL_DIR)/$(APP_NAME).1
	@if [ ! -f $(CONF_INSTALL_DIR)/$(APP_NAME).conf ]; then \
		install -m 644 $(CONF_DIR)/$(APP_NAME).conf $(CONF_INSTALL_DIR)/$(APP_NAME).conf; \
		echo "Installed config file to $(CONF_INSTALL_DIR)/$(APP_NAME).conf"; \
	else \
		echo "Config file already exists at $(CONF_INSTALL_DIR)/$(APP_NAME).conf (not overwriting)"; \
	fi
	@echo "Installed $(APP_NAME) to $(BIN_DIR)/$(APP_NAME)"
	@echo "Installed man page to $(MAN_INSTALL_DIR)/$(APP_NAME).1"
	@echo ""
	@echo "Installation complete!"
	@echo "Run '$(APP_NAME)' to use the application"
	@echo "Run 'man $(APP_NAME)' to view the manual"
	@echo "Edit $(CONF_INSTALL_DIR)/$(APP_NAME).conf to customize appearance"

# Uninstall the application
uninstall:
	@echo "Uninstalling $(APP_NAME)..."
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
	@echo "  make build      - Build the application (default)"
	@echo "  make run        - Build and run the application"
	@echo "  make install    - Install to $(BIN_DIR)"
	@echo "  make uninstall  - Remove installed files"
	@echo "  make test       - Run tests"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make help       - Show this help message"
