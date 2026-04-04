# mdv - Markdown Viewer for Coding Agents

![image](docs/screenshot.png)

A native macOS Markdown viewer launchable from the CLI, with Mermaid diagram rendering support.
Useful as a preview tool for coding agents — add `mdv` to your AGENTS.md to let agents preview Markdown files.

## Features

### Rendering
- Mermaid diagrams (click to zoom, pan and zoom controls)
- Math formulas (KaTeX)
- Syntax highlighting with copy button
- YAML frontmatter (GitHub-style)

### Navigation
- Native macOS tab UI with cross-window tab dragging
- Table of Contents sidebar
- In-document search (Cmd+F)
- Context menu (copy file path, relative path with line numbers, copy as Markdown)

### Integration
- CLI tool (`mdv file.md`)
- Live reload on file changes
- Dark mode support
- Homebrew Cask distribution

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
