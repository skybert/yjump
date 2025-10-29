# yjump

A fast window switcher for macOS with fuzzy search, inspired by rofi
on Linux/i3.

## Installation

```bash
make install
```

## Bind yjump to a shortcut

You can either use Automator, create a service there and hook that
service up to a shortcut, or take the easy route, install
[Hammerspoon](https://www.hammerspoon.org) and add the following to
`~/.hammerspoon/init.lua`:

```lua
 hs.hotkey.bind({"shift", "ctrl"}, "o", function()
    hs.execute("~/.local/bin/yjump")
  end)
```

