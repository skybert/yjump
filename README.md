# yjump

A fast window switcher for macOS with fuzzy search, inspired by rofi on Linux/i3.

## Features

- **Live Filtering**: Window list updates in real-time as you type
- **Fuzzy Search**: Quickly find windows by typing any part of the window title or application name
- **Cross-Workspace**: Jump to windows across all macOS Spaces/Desktops
- **Keyboard-Driven**: Entirely controlled via keyboard for maximum efficiency
- **Themeable**: Customize colors, fonts, size, and position via configuration file
- **Fast**: Optimized Swift implementation for snappy performance
- **XDG Compliant**: Configuration follows XDG Base Directory specification

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
- Example config to `~/.config/yjump/yjump.conf` (if not already present)

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

1. **Type** to search for windows - the list appears and filters in real-time
2. **↑/↓** arrow keys to select from the filtered list
3. **Enter** to activate the selected window
4. **Esc** to cancel

## Keyboard Shortcuts

- `Type` - Search and filter windows in real-time
- `↑` - Move selection up in the list
- `↓` - Move selection down in the list
- `Enter` - Activate selected window and quit
- `Esc` - Quit without switching

## Configuration

yjump can be customized via a configuration file. Create or edit:

```bash
~/.config/yjump/yjump.conf
```

Or use the XDG_CONFIG_HOME location:

```bash
$XDG_CONFIG_HOME/yjump/yjump.conf
```

### Example Configuration

See `conf/yjump.conf` for a complete example with all available options:

```conf
# Window appearance
window_width = 600
window_height = 50

# Colors (hex format)
background_color = #2E3440
text_color = #ECEFF4
placeholder_color = #4C566A
selection_color = #5E81AC
border_color = #3B4252

# Border
border_width = 2
corner_radius = 8

# Font
font_name = Menlo
font_size = 16

# Behavior
max_results = 10
case_sensitive = false

# Window position (center, top, bottom, or x,y coordinates)
position = center
```

### Configuration Options

- `window_width`, `window_height` - Window dimensions in pixels
- `background_color`, `text_color`, `placeholder_color`, `selection_color`, `border_color` - Colors in hex format
- `border_width` - Border thickness in pixels
- `corner_radius` - Corner roundness in pixels
- `font_name` - Font family name (e.g., Menlo, Monaco, SF Mono)
- `font_size` - Font size in points
- `max_results` - Maximum number of results to consider
- `case_sensitive` - Enable case-sensitive search (true/false)
- `position` - Window position: `center`, `top`, `bottom`, or `x,y` coordinates

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
├── conf/
│   └── yjump.conf      # Example configuration
├── Makefile            # Build system
└── README.md           # This file
```

## License

Free software - you are free to change and redistribute it.

## Inspiration

Inspired by rofi and other fast window switchers on Linux/i3.

