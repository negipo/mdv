import AppKit

extension MarkdownWindowController {
    private static let helpFileName = "mdv-shortcuts.md"

    private static var helpFilePath: String {
        (NSTemporaryDirectory() as NSString).appendingPathComponent(helpFileName)
    }

    private static var sendKeyLabel: String {
        SendTarget.isConfigured ? "Send to \(SendTarget.appName ?? "App")" : "Send to App / Open Settings"
    }

    private static var sendMenuLabel: String {
        SendTarget.isConfigured ? "Send to \(SendTarget.appName ?? "App")" : "Send to\u{2026}"
    }

    @objc func showShortcutHelp(_ sender: Any? = nil) {
        let path = Self.helpFilePath
        try? generateShortcutHelpContent().write(toFile: path, atomically: true, encoding: .utf8)
        WindowManager.shared.openOrFocus(filePath: path)
    }

    func generateShortcutHelpContent() -> String {
        [
            "# Keyboard Shortcuts & Mouse Manipulations",
            Self.singleKeyShortcutsSection,
            Self.menuShortcutsSection,
            Self.mouseManipulationsSection
        ].joined(separator: "\n\n") + "\n"
    }

    private static var singleKeyShortcutsSection: String {
        """
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
| `s` | \(sendKeyLabel) |
| `?` | Show this help |
"""
    }

    private static var menuShortcutsSection: String {
        """
## Menu Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+O` | Open File |
| `Cmd+W` | Close Tab |
| `Cmd+Shift+T` | Reopen Closed Tab |
| `Cmd+F` | Find |
| `Cmd+S` | \(sendMenuLabel) |
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
    }

    private static var mouseManipulationsSection: String {
        """
## Mouse Manipulations

### Mermaid Diagram Overlay

| Action | Behavior |
|--------|----------|
| Click | Open overlay |
| Scroll | Zoom in/out at cursor |
| Drag | Pan (move) |
| `Esc` | Close overlay |
"""
    }
}
