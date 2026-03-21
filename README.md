# mdv

<img width="1392" height="1087" alt="image" src="https://github.com/user-attachments/assets/928bee99-dc9d-4e31-9c95-53026798ef68" />

A native macOS Markdown viewer launchable from the CLI, with Mermaid diagram rendering support.
Useful as a preview tool for coding agents — add `mdv` to your CLAUDE.md to let agents preview Markdown files.

## Features

- Mermaid diagram rendering
- Native macOS tab UI
- Syntax highlighting
- Live reload on file changes

## Installation

Download the latest zip from [Releases](https://github.com/negipo/mdv/releases), extract it, and move `mdv.app` to `/Applications`.

On first launch, macOS may show a warning about an unidentified developer. Run the following command before launching:

```bash
xattr -cr /Applications/mdv.app
```

## Installation from Source

Requires Xcode (including Command Line Tools) and Node.js.

```bash
git clone https://github.com/negipo/mdv.git
cd mdv
npm install
npm run install:local
```

## Usage

On first launch, open mdv.app from Finder to install the CLI command. After that, you can use it from the terminal:

```bash
mdv path/to/file.md
```

## Development

Requires Xcode (including Command Line Tools) and Node.js.

```bash
npm run build:js  # Build JS bundle
npm test          # Run tests
npm run lint      # Type check
npm run build     # JS bundle + Xcode build
```

## License

MIT
