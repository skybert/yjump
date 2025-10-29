#!/usr/bin/env bash
# Install SwiftFormat for code formatting
# Works on macOS and Linux

set -euo pipefail

# Constants
readonly SWIFTFORMAT_VERSION="0.54.3"
readonly INSTALL_DIR="${HOME}/.local/bin"

# Print message with color
print_info() {
  echo "→ $*"
}

print_success() {
  echo "✅ $*"
}

print_error() {
  echo "❌ $*" >&2
}

print_warning() {
  echo "⚠️  $*"
}

# Detect operating system
detect_os() {
  case "$OSTYPE" in
    darwin*)
      echo "macos"
      ;;
    linux-gnu*)
      echo "linux"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Check if command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Verify SwiftFormat installation
verify_installation() {
  if command_exists swiftformat; then
    print_success "SwiftFormat installed successfully!"
    swiftformat --version
    return 0
  elif [ -x "${INSTALL_DIR}/swiftformat" ]; then
    print_success "SwiftFormat installed successfully!"
    "${INSTALL_DIR}/swiftformat" --version
    return 0
  else
    print_error "SwiftFormat installation failed"
    return 1
  fi
}

# Install via Homebrew on macOS
install_via_homebrew() {
  print_info "Installing via Homebrew..."
  if brew install swiftformat; then
    return 0
  else
    print_warning "Homebrew installation failed, falling back to manual install"
    return 1
  fi
}

# Download and install binary from GitHub releases
install_from_github_macos() {
  local binary_url="https://github.com/nicklockwood/SwiftFormat/releases/download/${SWIFTFORMAT_VERSION}/swiftformat.zip"
  local temp_dir
  temp_dir=$(mktemp -d)
  
  print_info "Downloading SwiftFormat ${SWIFTFORMAT_VERSION} for macOS..."
  
  mkdir -p "${INSTALL_DIR}"
  cd "${temp_dir}"
  
  if curl -L -o swiftformat.zip "${binary_url}"; then
    unzip -q -o swiftformat.zip
    mv swiftformat "${INSTALL_DIR}/"
    chmod +x "${INSTALL_DIR}/swiftformat"
    cd - >/dev/null
    rm -rf "${temp_dir}"
    print_success "SwiftFormat installed to ${INSTALL_DIR}/swiftformat"
    return 0
  else
    cd - >/dev/null
    rm -rf "${temp_dir}"
    print_error "Failed to download SwiftFormat"
    return 1
  fi
}

# Install on macOS
install_macos() {
  if command_exists brew; then
    install_via_homebrew && return 0
  else
    print_info "Homebrew not found, installing from GitHub releases..."
  fi
  
  install_from_github_macos
}

# Install on Linux
install_linux() {
  local binary_url="https://github.com/nicklockwood/SwiftFormat/releases/download/${SWIFTFORMAT_VERSION}/swiftformat_linux.zip"
  local temp_dir
  temp_dir=$(mktemp -d)
  
  print_info "Downloading SwiftFormat ${SWIFTFORMAT_VERSION} for Linux..."
  
  mkdir -p "${INSTALL_DIR}"
  cd "${temp_dir}"
  
  if curl -L -f -o swiftformat_linux.zip "${binary_url}" 2>/dev/null; then
    unzip -q -o swiftformat_linux.zip
    mv swiftformat "${INSTALL_DIR}/"
    chmod +x "${INSTALL_DIR}/swiftformat"
    cd - >/dev/null
    rm -rf "${temp_dir}"
    print_success "SwiftFormat installed to ${INSTALL_DIR}/swiftformat"
    return 0
  else
    cd - >/dev/null
    rm -rf "${temp_dir}"
    print_error "Pre-built binary not available for Linux."
    print_info "You'll need to build from source or install via Swift Package Manager."
    print_info "See: https://github.com/nicklockwood/SwiftFormat#installation"
    return 1
  fi
}

# Main installation function
main() {
  local os_type
  os_type=$(detect_os)
  
  print_info "Installing SwiftFormat ${SWIFTFORMAT_VERSION}..."
  
  case "$os_type" in
    macos)
      install_macos
      ;;
    linux)
      install_linux
      ;;
    *)
      print_error "Unsupported OS: $OSTYPE"
      return 1
      ;;
  esac
  
  local exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
    verify_installation
  else
    return $exit_code
  fi
}

# Run main function
main "$@"
