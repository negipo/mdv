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
