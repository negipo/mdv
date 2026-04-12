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
- When a PreToolUse hook blocks a tool call, do not attempt workarounds. Report the block to the user and wait for instructions.
- When changing user-facing features (menus, shortcuts, integrations, etc.), check whether README.md describes those features and update accordingly.

## Adding Resources

When adding new files to `mdv/Resources/`, run `xcodegen generate` before building. Without this, the Xcode project won't include the new files in the app bundle.

## Manual UI Verification

When verifying UI changes, kill the running app, rebuild, and relaunch for the user to check.
Do NOT use `/Applications/mdv.app` or the `mdv` CLI command — these point to a previously installed version, not the current build. Always launch from DerivedData with absolute paths:

```bash
pkill -x mdv 2>/dev/null
xcodebuild -scheme mdv -configuration Debug build 2>&1 | tail -5
open ~/Library/Developer/Xcode/DerivedData/mdv-.../Build/Products/Debug/mdv.app --args "$(pwd)/fixtures/comprehensive.md"
```
