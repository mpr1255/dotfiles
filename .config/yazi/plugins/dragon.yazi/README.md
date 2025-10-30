# Yazi Dragon Plugin

A plugin for the [Yazi](https://github.com/sxyazi/yazi) file manager that provides drag-and-drop functionality using [dragon](https://github.com/mwh/dragon).

## Features

- Drag single files or multiple selections
- Automatic path escaping for special characters
- Works with both X11 and Wayland
- Auto-exits after successful drag operation

## Prerequisites

- Yazi file manager
- dragon (available in most package managers)

## Installation

### Using Home Manager

Add to your Yazi configuration:

```nix
programs.yazi = {
  plugins = {
    dragon = pkgs.fetchFromGitHub {
      owner = "R4Sput1n";
      repo = "yazi-dragon";
      rev = "main";
      hash = "sha256-...";  # Use nix-prefetch-github to get this
    } + "/dragon.yazi";
  };
};
```

### Manual Installation

```bash
# Using git
git clone https://github.com/R4Sput1n/yazi-dragon ~/.config/yazi/plugins/dragon
```

# Or manually
```bash
mkdir -p ~/.config/yazi/plugins/dragon
curl -o ~/.config/yazi/plugins/dragon/init.lua https://raw.githubusercontent.com/R4Sput1n/yazi-dragon/main/init.lua
```

## Usage
1. In Yazi, select one or multiple files (optional)
2. Press 'd' -> 'r' (or whatever is your keymap setting) to initiate drag-and-drop
3. Drag the file(s) to your target application
4. The dragon window will close automatically after successful drop

## Configuration
### Home-Manager
```nix
manager.prepend_keymap = [
  {
    on = [ "d" "r" ],
    run = "plugin dragon",
    desc = "Drag file(s) with dragon",
  },
]
```

### Keymap-Toml
```toml
[[manager.prepend_keymap]]
on   = [ "d", "r" ]
run  = "plugin dragon"
desc = "Drag file(s) with dragon"
```
