#!/bin/bash
set -e

echo "Building Pomodoro/B Release DMG..."

# 1. Read version
VERSION=$(xcodebuild -project Pomodoro.xcodeproj -showBuildSettings | grep MARKETING_VERSION | awk '{print $3}')
if [ -z "$VERSION" ]; then
    echo "Error: Could not determine MARKETING_VERSION."
    exit 1
fi
echo "Version detected: $VERSION"

# 2. Build the app
echo "Cleaning old builds..."
rm -rf build/ dist/staging/
mkdir -p dist/staging

echo "Compiling Release build..."
xcodebuild -scheme Pomodoro \
           -configuration Release \
           -derivedDataPath build \
           SYMROOT=build \
           -quiet

APP_PATH="build/Release/Pomodoro.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App build failed or app not found at $APP_PATH"
    exit 1
fi

echo "Staging app..."
cp -R "$APP_PATH" dist/staging/

# 4. Create DMG
DMG_NAME="Pomodoro-B-v${VERSION}.dmg"
DMG_PATH="dist/${DMG_NAME}"

# Remove existing DMG if any
rm -f "$DMG_PATH"

echo "Creating DMG..."
create-dmg \
  --volname "Pomodoro-B v${VERSION}" \
  --window-pos 200 120 \
  --window-size 560 340 \
  --icon-size 100 \
  --background "scripts/dmg_background.png" \
  --icon "Pomodoro.app" 140 170 \
  --hide-extension "Pomodoro.app" \
  --app-drop-link 420 170 \
  --no-internet-enable \
  "$DMG_PATH" \
  "dist/staging/"

# Check if signing/notarizing is available - we just report status
echo "Code signature status:"
codesign -dv --verbose=4 "$APP_PATH" || echo "App is not strictly signed or Developer ID is missing."

echo ""
echo "==================================="
echo "Build complete!"
echo "Version: $VERSION"
echo "Output: $DMG_PATH"
echo "==================================="
