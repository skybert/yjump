# yjump

A fast window switcher for macOS with fuzzy search, inspired by rofi on Linux/i3.

## Features

- **Fuzzy Search**: Quickly find windows by typing parts of the window title or application name
- **Cross-Workspace**: Jump to windows across all macOS Spaces/Desktops
- **Keyboard-Driven**: Entirely controlled via keyboard for maximum efficiency
- **Fast**: Optimized Swift implementation for snappy performance
- **Simple**: Clean interface focused on speed and usability

## Installation

### Build from source

```bash
make build
```

### Install

```bash
make install
```

This installs:
- `yjump` binary to `~/.local/bin/yjump`
- Man page to `~/.local/share/man/man1/yjump.1`

Make sure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Uninstall

```bash
make uninstall
```

## Usage

Launch yjump:

```bash
yjump
```

Once the interface appears:

1. **Type** to search for windows (fuzzy matching)
2. **↑/↓** arrow keys to navigate
3. **Enter** to activate the selected window
4. **Esc** to cancel

## Keyboard Shortcuts

- `↑` - Move selection up
- `↓` - Move selection down
- `Enter` - Activate selected window and quit
- `Esc` - Quit without switching

## Permissions

yjump requires **Accessibility permissions** to function. On first run, macOS will prompt you to grant these permissions.

Alternatively, enable manually:
1. Open **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Add yjump (or your terminal application) to the list

## Man Page

View the manual page:

```bash
man yjump
```

## Development

### Build

```bash
make build
```

### Run

```bash
make run
```

### Clean

```bash
make clean
```

### Test

```bash
make test
```

## Requirements

- macOS 10.14 or later
- Swift 5.0+
- Xcode Command Line Tools

## Project Structure

```
yjump/
├── src/
│   └── main.swift      # Main application code
├── man/
│   └── yjump.1         # Man page
├── Makefile            # Build system
└── README.md           # This file
```

## License

Free software - you are free to change and redistribute it.

## Inspiration

Inspired by rofi and other fast window switchers on Linux/i3.

