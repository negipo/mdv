import AppKit

extension MarkdownWindowController {
    private static let helpFileName = "mdv-shortcuts.md"

    private static var helpFilePath: String {
        (NSTemporaryDirectory() as NSString).appendingPathComponent(helpFileName)
    }

    func showShortcutHelp() {
        let path = Self.helpFilePath
        let content = """
# Keyboard Shortcuts

## Single-Key Shortcuts

| Key | Action |
|-----|--------|
| `j` | Scroll half-page down |
| `k` | Scroll half-page up |
| `g` | Scroll to top |
| `G` | Scroll to bottom |
| `/` | Open search bar |
| `n` | Next search result |
| `N` | Previous search result |
| `q` | Close tab |
| `t` | Toggle Table of Contents |
| `r` | Reload |
| `c` | Copy Relative Path |
| `C` | Copy Absolute Path |
| `l` | Copy Relative Path with Lines |
| `y` | Copy Path:Line + Content |
| `m` | Copy File as Markdown |
| `s` | Send to Ghostty |
| `?` | Show this help |

## Menu Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+O` | Open File |
| `Cmd+W` | Close Tab |
| `Cmd+Shift+T` | Reopen Closed Tab |
| `Cmd+F` | Find |
| `Cmd+G` | Send to Ghostty |
| `Cmd+R` | Reload |
| `Cmd+T` | Table of Contents |
| `Cmd++` | Zoom In |
| `Cmd+-` | Zoom Out |
| `Cmd+0` | Actual Size |
| `Cmd+Shift+C` | Copy Relative Path |
| `Cmd+Shift+L` | Copy Relative Path with Lines |
| `Cmd+L` | Copy Path:Line + Content |
| `Cmd+Shift+Option+C` | Copy Absolute Path |
| `Cmd+Shift+M` | Copy File as Markdown |
| `Cmd+Ctrl+F` | Toggle Full Screen |
"""
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
        WindowManager.shared.openOrFocus(filePath: path)
    }
}
