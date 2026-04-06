import AppKit

extension MarkdownWindowController {
    func generateSendContent(action: SendToTerminalAction) -> String? {
        guard let path = filePath else { return nil }

        switch action {
        case .relativePath:
            return relativePath(for: path)

        case .relativePathWithLines:
            let rel = relativePath(for: path)
            guard let info = cachedLineInfo else { return rel }
            if info.startLine == info.endLine {
                return "\(rel):\(info.startLine)"
            }
            return "\(rel):\(info.startLine)-\(info.endLine)"

        case .pathLineContent:
            let rel = relativePath(for: path)
            guard let info = cachedLineInfo else { return rel }
            if info.startLine == info.endLine {
                return "\(rel):\(info.startLine)"
            }
            return "\(rel):\(info.startLine)-\(info.endLine)"

        case .absolutePath:
            return path

        case .fileAsMarkdown:
            return try? String(contentsOfFile: path, encoding: .utf8)
        }
    }

    func sendToTerminal() {
        let action = SendToTerminalAction.current
        if action == .pathLineContent {
            sendToTerminalWithEvaluation()
            return
        }

        guard let content = generateSendContent(action: action) else { return }
        pasteToGhostty(content)
    }

    private func sendToTerminalWithEvaluation() {
        guard let path = filePath else { return }
        let rel = relativePath(for: path)

        evaluateSelectionInfo { [weak self] info, text in
            let content: String
            if let info = info {
                if info.startLine == info.endLine {
                    content = "\(rel):\(info.startLine) \(text)"
                } else {
                    content = "\(rel):\(info.startLine)-\(info.endLine)\n\(text)"
                }
            } else {
                content = rel
            }
            self?.pasteToGhostty(content)
        }
    }

    func pasteToGhostty(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)

        let script = """
        tell application "Ghostty" to activate
        delay 0.1
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
