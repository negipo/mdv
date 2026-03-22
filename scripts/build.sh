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
  hdiutil create -volname "mdv" \
    -srcfolder "$APP_PATH" \
    -ov -format UDZO "$DMG_NAME"
  echo "Created $DMG_NAME"
fi
