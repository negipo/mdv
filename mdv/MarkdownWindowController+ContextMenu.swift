import AppKit

extension MarkdownWindowController {
    func buildContextMenuItems(menu: NSMenu) {
        menu.addItem(.separator())

        let relativeItem = NSMenuItem(
            title: "Copy Relative Path",
            action: #selector(copyRelativePath(_:)),
            keyEquivalent: ""
        )
        relativeItem.target = self
        menu.addItem(relativeItem)

        if cachedLineInfo != nil {
            let linesItem = NSMenuItem(
                title: "Copy Relative Path with Lines",
                action: #selector(copyRelativePathWithLines(_:)),
                keyEquivalent: ""
            )
            linesItem.target = self
            menu.addItem(linesItem)

            let linesContentItem = NSMenuItem(
                title: "Copy Path:Line + Content",
                action: #selector(performCopyRelativePathWithLinesAndContent(_:)),
                keyEquivalent: ""
            )
            linesContentItem.target = self
            menu.addItem(linesContentItem)
        }

        let pathItem = NSMenuItem(
            title: "Copy Absolute Path",
            action: #selector(copyFullPath(_:)),
            keyEquivalent: ""
        )
        pathItem.target = self
        menu.addItem(pathItem)

        menu.addItem(.separator())

        let contentItem = NSMenuItem(
            title: "Copy File as Markdown",
            action: #selector(copyContent(_:)),
            keyEquivalent: ""
        )
        contentItem.target = self
        menu.addItem(contentItem)

        menu.addItem(.separator())

        let sendItem = NSMenuItem(
            title: SendTarget.menuTitle,
            action: #selector(sendToAppFromContextMenu(_:)),
            keyEquivalent: ""
        )
        sendItem.target = self
        menu.addItem(sendItem)
    }

    @objc func sendToAppFromContextMenu(_ sender: Any?) {
        guard SendTarget.isConfigured else {
            openSettingsForSendTarget()
            return
        }

        let action = SendToAppAction.current
        if action == .pathLineContent, let info = cachedLineInfo {
            evaluateSelectedText { [weak self] text in
                guard let self = self, let path = self.filePath else { return }
                let rel = self.relativePath(for: path)
                let content: String
                if info.startLine == info.endLine {
                    content = "\(rel):\(info.startLine) \(text)"
                } else {
                    content = "\(rel):\(info.startLine)-\(info.endLine)\n\(text)"
                }
                self.pasteToApp(content)
            }
            return
        }

        guard let content = generateSendContent(action: action) else { return }
        pasteToApp(content)
    }

    @objc func copyFullPath(_ sender: Any?) {
        guard let path = filePath else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)
    }

    @objc func copyRelativePath(_ sender: Any?) {
        guard let path = filePath else { return }
        let rel = relativePath(for: path)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(rel, forType: .string)
    }

    @objc func copyRelativePathWithLines(_ sender: Any?) {
        guard let path = filePath, let info = cachedLineInfo else { return }
        let rel = relativePath(for: path)
        let result: String
        if info.startLine == info.endLine {
            result = "\(rel):\(info.startLine)"
        } else {
            result = "\(rel):\(info.startLine)-\(info.endLine)"
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(result, forType: .string)
    }

    @objc func copyContent(_ sender: Any?) {
        guard let path = filePath,
              let content = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }

    @objc func performCopyRelativePathWithLines(_ sender: Any?) {
        guard let path = filePath else { return }
        let rel = relativePath(for: path)

        evaluateSelectionInfo { info, _ in
            guard let info = info else { return }
            let result: String
            if info.startLine == info.endLine {
                result = "\(rel):\(info.startLine)"
            } else {
                result = "\(rel):\(info.startLine)-\(info.endLine)"
            }
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(result, forType: .string)
        }
    }

    @objc func performCopyRelativePathWithLinesAndContent(_ sender: Any?) {
        guard let path = filePath else { return }
        let rel = relativePath(for: path)

        evaluateSelectionInfo { info, text in
            guard let info = info else { return }
            let result: String
            if info.startLine == info.endLine {
                result = "\(rel):\(info.startLine) \(text)"
            } else {
                result = "\(rel):\(info.startLine)-\(info.endLine)\n\(text)"
            }
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(result, forType: .string)
        }
    }

    func copyRelativePathWithLinesAndContent(_ sender: Any?, lineInfo: LineInfo, selectedText: String) {
        guard let path = filePath else { return }
        let rel = relativePath(for: path)
        let result: String
        if lineInfo.startLine == lineInfo.endLine {
            result = "\(rel):\(lineInfo.startLine) \(selectedText)"
        } else {
            result = "\(rel):\(lineInfo.startLine)-\(lineInfo.endLine)\n\(selectedText)"
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(result, forType: .string)
    }
}
