# Papir

Papir is a fast, private scratchpad that lives in your macOS menu bar. Open it, type or paste anything, and return to your work. Your note is saved automatically and never leaves your Mac.

## Features

- Instant access from the menu bar or a global keyboard shortcut
- Plain-text editing with automatic local saving
- Detachable floating panel that stays above other windows
- Configurable font, font size, and keyboard shortcut
- Optional launch at login
- Dark Mode and accessibility support
- No accounts, analytics, advertising, or network requests

## Requirements

- macOS 14 or later
- Apple Silicon Mac

## Installation

Download the latest signed and notarized ZIP from [GitHub Releases](../../releases/latest), extract it, and move **Papir.app** to your Applications folder.

Papir runs only in the menu bar and does not appear in the Dock.

## Usage

Click the Papir icon in the menu bar or press `Control–Option–T` to open the scratchpad. The same shortcut dismisses it.

Use the controls at the bottom of the scratchpad to:

- detach Papir into a floating window;
- open Settings;
- quit the app.

When detached, the keyboard shortcut shows or hides the floating window. Papir remembers its position.

The default shortcut can be changed in Settings. Notes are limited to 100,000 characters.

## Privacy

Papir stores your note and preferences locally on your Mac. It does not collect data or make network requests. See the full [Privacy Policy](PRIVACY.md).

## Development

Papir is a native macOS app built with Swift, SwiftUI, and AppKit. It has no third-party runtime dependencies.

Open `Papir.xcodeproj` in Xcode and run the **Papir** scheme on **My Mac**, or use the command line:

```sh
xcodebuild test \
  -project Papir.xcodeproj \
  -scheme Papir \
  -destination 'platform=macOS,arch=arm64'
```

The project definition is kept in `project.yml` and can be regenerated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
xcodegen generate
```

## Acknowledgements

Papir is inspired by [Tyke](https://tyke.app/), a wonderfully simple menu-bar scratchpad for macOS.
