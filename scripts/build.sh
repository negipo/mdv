#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

if [ "${CI:-}" = "true" ]; then
  npm ci
else
  npm install
fi

npm run build:js

xcodegen generate

if [ -n "${VERSION:-}" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" mdv/Info.plist
fi

if [ -n "${BUILD_NUMBER:-}" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" mdv/Info.plist
fi

xcodebuild build \
  -project mdv.xcodeproj \
  -scheme mdv \
  -configuration Release \
  -derivedDataPath build/

if [ -n "${VERSION:-}" ]; then
  APP_PATH="build/Build/Products/Release/mdv.app"
  DMG_NAME="mdv-${VERSION}-macos.dmg"
  create-dmg \
    --volname "mdv" \
    --window-size 600 400 \
    --icon-size 128 \
    --icon "mdv.app" 150 200 \
    --app-drop-link 450 200 \
    --no-internet-enable \
    "$DMG_NAME" "$APP_PATH"
  echo "Created $DMG_NAME"
fi
