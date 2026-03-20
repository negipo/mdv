#!/bin/bash
set -euo pipefail

fail() { echo "Error: $1" >&2; exit 1; }

which xcodebuild >/dev/null 2>&1 \
  || fail "xcodebuild not found. Please install Xcode from the App Store."

xcode_path=$(xcode-select -p 2>/dev/null || true)
[[ "$xcode_path" == *Xcode.app* ]] \
  || fail "Full Xcode installation required (Command Line Tools alone is not sufficient). Please install Xcode from the App Store."

xcodebuild -license check 2>/dev/null \
  || fail "Xcode license not accepted. Run: sudo xcodebuild -license accept"

which xcodegen >/dev/null 2>&1 \
  || fail "xcodegen not found. Install it with: brew install xcodegen"
