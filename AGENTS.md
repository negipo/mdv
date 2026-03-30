# mdv

A Markdown viewer app for macOS. Built with Swift (AppKit) + TypeScript (marked, mermaid, shiki).

## Build & Test

```bash
npm ci
npm run test:js    # JS tests (vitest)
npm run test:swift # Swift tests (xcodegen + xcodebuild)
npm run build      # Full build
```

## Development Rules

- Create a PR and merge into main. Avoid pushing directly to main.
- All user-facing UI text (menu items, labels, alerts, etc.) must be in English.
- Run `npm ci` to ensure dependencies are installed before running lint or tests. If a command fails with `command not found`, do not ignore it — investigate and resolve the cause.

## Manual UI Verification

When verifying UI changes, kill the running app, rebuild, and relaunch for the user to check:

```bash
pkill -x mdv 2>/dev/null
xcodebuild -scheme mdv -configuration Debug build 2>&1 | tail -5
open ~/Library/Developer/Xcode/DerivedData/mdv-afrghrsxmvulxhcshpjiumlziahy/Build/Products/Debug/mdv.app
```
