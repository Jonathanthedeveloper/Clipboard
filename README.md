# Clipboard

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-14.0+-black.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)

A lightweight clipboard history manager for macOS, inspired by Windows 11's clipboard menu (Win+V). Lives in your menu bar and gives you instant access to your clipboard history.

## Features

- **Global Hotkey** — Press `⌘⇧V` to open clipboard history from anywhere
- **Text & Image Support** — Stores both text snippets and images with thumbnails
- **Pin Favorites** — Keep important items pinned at the top
- **Instant Search** — Find items quickly by typing
- **Keyboard Navigation** — Use arrow keys and Enter to select
- **One-Click Paste** — Copy and paste into frontmost app instantly
- **Persistent History** — Saved across app restarts
- **Optimized** — Lazy image loading, compressed storage, low memory footprint

## Installation

### From Source

```bash
git clone https://github.com/Jonathanthedeveloper/Clipboard.git
cd Clipboard
open Clipboard.xcodeproj
```

1. Build and run the `Clipboard` scheme (⌘R)
2. The app appears as a paperclip icon in your menu bar

### Requirements

- macOS 14.0+ (Sonoma)
- Xcode 16+ (for building)

## Permissions

The app requires **Accessibility** permission for:
- Global hotkey (`⌘⇧V`)
- Simulating paste (`⌘V`) into other apps

**To grant:**
1. Open **System Settings → Privacy & Security → Accessibility**
2. Click **+** and add **Clipboard.app**
3. Enable the checkbox
4. Restart the app

## Usage

| Action | Shortcut |
|--------|----------|
| Open Clipboard | `⌘⇧V` or click menu bar |
| Navigate | `↑` `↓` |
| Copy item | `Enter` |
| Close | `Esc` |
| Search | Start typing |

### Screenshots to Clipboard

Use these shortcuts to capture screenshots directly to clipboard:

| Action | Shortcut |
|--------|----------|
| Full screen | `⌃⌘⇧3` |
| Selection | `⌃⌘⇧4` |

> **Tip:** In Screenshot.app (`⌘⇧5`) → Options → Save to → Clipboard

## Architecture

```
Clipboard/
├── ClipboardApp.swift        # App entry, MenuBarExtra
├── GlobalHotkeyManager.swift # CGEvent tap for global hotkey
├── ContentView.swift         # SwiftUI interface
├── ClipboardManager.swift    # Clipboard monitoring & persistence
├── ClipboardItem.swift       # Data model
└── ImageCache.swift          # LRU image cache
```

## Roadmap

- [ ] Smart search with regex support
- [ ] Paste stack (sequential copy/paste)
- [ ] Text scrubbing (strip formatting, trim whitespace)
- [ ] Hotkey-based item selection (Cmd+1..9)
- [ ] Snippets and text expansion support

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
