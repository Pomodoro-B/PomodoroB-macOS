# Pomodoro/B macOS

Pomodoro/B is a beautifully designed, native macOS menubar Pomodoro timer built with SwiftUI. It provides strict time management cycles with a meticulously polished aesthetic.

## Features
- **Native Menubar App**: Lives quietly in your Mac's menu bar for instant access without cluttering the Dock.
- **Adjustable Timers**: Customize the length of your Focus, Short Break, and Long Break durations directly from the settings.
- **Smart Session Automation**: Optionally auto-start the next chronological session (e.g. Focus -> Short Break) automatically.
- **Dark Mode**: Explicitly override the UI theme with a custom-built gorgeous Dark Mode palette, or leave it matching your system.

## Installation
The easiest way to install Pomodoro/B is to download the compiled drag-and-drop installer:
1. Navigate to the [GitHub Releases](https://github.com/Pomodoro-B/PomodoroB-macOS/releases) page.
2. Download the latest `Pomodoro-B-v<version>.dmg` asset.
3. Open the `.dmg` and drag the application into the Applications folder.

*(Note: Because this app is distributed outside the Mac App Store and currently signed ad-hoc, you may need to right-click -> Open the first time, or allow it in System Settings > Privacy & Security).*

## Building from Source
Pomodoro/B requires Xcode and targets macOS 14.0+.

1. Clone the repository.
2. Open `Pomodoro.xcodeproj` in Xcode.
3. Select the `Pomodoro` scheme and build.

Alternatively, to generate your own release DMG:
```bash
# Requires Xcode and create-dmg (brew install create-dmg)
chmod +x scripts/build-release.sh
./scripts/build-release.sh
```
