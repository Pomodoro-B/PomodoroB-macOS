# Change Audit

## New Features
- **Customizable Durations**: Added Steppers in Settings for Focus, Short Break, and Long Break durations, synced instantly to `UserDefaults` (Implemented and Verified).
- **Appearance Settings**: Added a macOS-native Dark Mode toggle allowing explicit theme overriding, matching Pomodoro/B's color palette (Implemented and Verified).
- **Release Automation**: Introduced `build-release.sh` to compile, package, and generate a polished `.dmg` drag-and-drop installer natively (Implemented and Verified).

## UI and Visual Improvements
- **Timer Outline Animation**: Completely rebuilt the timer ring using a fixed horizontal grey track and a precisely trimmed blue `Capsule` stroke. 
- **Exact Color Palette**: Centralized NSColor/Color references matching the exact design mockups (Dark Aqua/Aqua variants).
- **Settings Toggle Alignment**: Rebuilt native Toggles using `HStack` and `Spacer()` to force perfect leading/trailing separation.
- **DMG Installer Aesthetic**: Authored a custom Swift script to generate a polished `560x340` installer background featuring a directional arrow and typography, replacing the empty default Finder view.

## Bug Fixes
- **Timer Geometry Misalignment**: Removed an erroneous `rotationEffect` that squished the blue ring vertically against the horizontal grey track.
- **State Propagation Delay**: Bound Settings edits (`focusDurationMinutes`, etc.) directly to the `remainingTime` via `didSet`, ensuring instant refreshes on the main menu without phantom resets.
- **Back Button Hit Area**: Increased the invisible clickable area on the Settings return button via `.padding()` and `.contentShape(Rectangle())`.

## Build and Release Tooling
- Implemented `/scripts/build-release.sh` using `create-dmg` and native AppleScripts.
- Updated `MARKETING_VERSION` to `0.2.0` via `agvtool` to reflect the comprehensive UI updates and features.
