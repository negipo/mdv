# mdv - Markdown Viewer for Coding Agents

![image](docs/screenshot.png)

A native macOS Markdown viewer launchable from the CLI, with Mermaid diagram rendering support.
Useful as a preview tool for coding agents — add `mdv` to your AGENTS.md to let agents preview Markdown files.

## Features

- Mermaid diagram rendering
- Native macOS tab UI
- Syntax highlighting
- Live reload on file changes

## Installation and Usage

```bash
brew install --cask negipo/tap/mdv
xattr -dr com.apple.quarantine /Applications/mdv.app
```

## Development

Requires Xcode (including Command Line Tools) and Node.js.

```bash
git clone https://github.com/negipo/mdv.git
cd mdv
npm install
npm run install:local  # Build and install locally
```

```bash
npm run build:js  # Build JS bundle
npm test          # Run tests
npm run lint      # Type check
npm run build     # JS bundle + Xcode build
```

## License

MIT
