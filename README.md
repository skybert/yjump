# yjump

A fast window switcher for macOS with fuzzy search, inspired by rofi on Linux/i3.

## Features

- **Live Filtering**: Window list updates in real-time as you type
- **Fuzzy Search**: Quickly find windows by typing any part of the window title or application name
- **Cross-Workspace**: Jump to windows across all macOS Spaces/Desktops
- **Keyboard-Driven**: Entirely controlled via keyboard for maximum efficiency
- **Themeable**: Customize colors, fonts, size, and position via configuration file
- **Fast**: Optimized with window list caching and smart API usage
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
window_width = 700
window_height = 50

# Colors (hex format - Nord theme)
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
font_size = 14

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
- `cache_window_list` - Cache window list for faster performance (true/false)
- `cache_timeout_seconds` - How long to cache window list in seconds (default: 2.0)

## Keyboard Shortcut Setup

macOS doesn't allow setting global hotkeys via command line, but yjump includes a helper script:

```bash
./bin/setup-hotkey.sh
```

This creates a macOS Quick Action that you can bind to a keyboard shortcut:

1. Run the setup script above
2. Open **System Preferences** → **Keyboard** → **Shortcuts**
3. Select **Services** in the left sidebar
4. Find **"yjump Launcher"** in the right panel
5. Click it and press **Add Shortcut**
6. Press your desired key combo (e.g., **Shift+Control+O**)

### Alternative: Third-Party Tools

For more control, use one of these:

**Hammerspoon** (recommended - free & powerful):
```lua
-- Add to ~/.hammerspoon/init.lua
hs.hotkey.bind({"shift", "ctrl"}, "o", function()
    hs.execute("~/.local/bin/yjump")
end)
```

**BetterTouchTool** (paid - most user-friendly):
- Create global keyboard shortcut
- Set action to "Run Shell Command"
- Command: `~/.local/bin/yjump`

**Karabiner-Elements** (free - advanced):
- Complex keyboard customization
- Requires more configuration

## Permissions

yjump requires **Accessibility permissions** to function. On first run, macOS will prompt you to grant these permissions.

Alternatively, enable manually:
1. Open **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Add yjump (or your terminal application) to the list

### About Window Titles

macOS has limitations on accessing window titles:
- **Firefox**: Provides window titles ✅
- **Chrome, Safari, Edge, Arc**: Typically don't expose individual window/tab titles ❌
- **Terminal**: Shows window titles ✅
- **Text Editors**: Usually show filenames ✅
- yjump will show window titles when available, otherwise just the application name
- Even with Accessibility permissions, some apps don't provide this information

**What you'll see:**
- **Firefox**: "Firefox: Page Title"
- **Terminal**: "Terminal: bash" or "Terminal: [window title]"
- **Chrome/Safari/Edge**: Usually just "Chrome", "Safari", etc. (per-tab titles not accessible)
- **Text Editors**: Often shows the filename
- **Other apps**: Varies by application

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

## Command Line Options

```bash
yjump --help     # Show help message
yjump --version  # Show version (from git tag/SHA)
yjump -h         # Short form of --help
yjump -v         # Short form of --version
```

## Project Structure

```
yjump/
├── src/
│   ├── cli.swift       # Command-line argument parsing
│   ├── conf.swift      # Configuration parsing
│   └── main.swift      # Main application code
├── tests/
│   ├── ConfigTests.swift      # Configuration tests
│   ├── FuzzyMatchTests.swift  # Fuzzy matching tests
│   └── WindowInfoTests.swift  # Window info tests
├── bin/
│   ├── setup-hotkey.sh        # Helper script for keyboard shortcut setup
│   └── install-swiftformat.sh # SwiftFormat installer
├── man/
│   └── yjump.1         # Man page
├── conf/
│   └── yjump.conf      # Example configuration
├── .swiftformat        # Code formatting rules
├── Makefile            # Build system with git versioning
├── CONTRIBUTING.md     # Contribution guidelines
└── README.md           # This file
```

## Development

### Code Formatting

This project uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to maintain consistent code style. Formatting happens automatically when you build:

```bash
make build  # Formats and builds
```

To install SwiftFormat:

```bash
make install-formatter
```

To format code manually:

```bash
make format
```

To check formatting (useful for CI):

```bash
make format-check
```

All formatting rules are defined in `.swiftformat` following Swift community best practices.

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

## License

Free software - you are free to change and redistribute it.

## Inspiration

Inspired by rofi and other fast window switchers on Linux/i3.

