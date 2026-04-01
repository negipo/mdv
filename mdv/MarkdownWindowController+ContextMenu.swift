import AppKit

extension MarkdownWindowController {
    func buildContextMenuItems(menu: NSMenu) {
        menu.addItem(.separator())

        let contentItem = NSMenuItem(
            title: "Copy File as Markdown",
            action: #selector(copyContent(_:)),
            keyEquivalent: ""
        )
        contentItem.target = self
        menu.addItem(contentItem)

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
        }

        let pathItem = NSMenuItem(
            title: "Copy Absolute Path",
            action: #selector(copyFullPath(_:)),
            keyEquivalent: ""
        )
        pathItem.target = self
        menu.addItem(pathItem)
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
}
