import AppKit
import WebKit

class NoBeepWebView: WKWebView {
    var onEscape: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            onEscape?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        guard let controller = window?.windowController as? MarkdownWindowController,
              controller.currentFilePath != nil else { return }

        controller.buildContextMenuItems(menu: menu)
    }
}

class MarkdownWindowController: NSWindowController, WKScriptMessageHandler, WKNavigationDelegate {
    struct LineInfo {
        let startLine: Int
        let endLine: Int
    }

    private var webView: NoBeepWebView!
    private var fileWatcher: FileWatcher?
    private var filePath: String?
    private var gitRoot: String?
    var cachedLineInfo: LineInfo?
    var currentFilePath: String? { filePath }
    private var isReady = false
    private var pendingMarkdown: String?
    private var pendingBasePath: String?
    private var currentZoom: CGFloat = 1.0

    var onWindowClose: ((String) -> Void)?
    var onWindowStateChange: ((NSWindow) -> Void)?

    init(windowState: WindowManager.WindowState) {
        let rect = NSRect(
            x: windowState.x ?? 200,
            y: windowState.y ?? 200,
            width: windowState.width,
            height: windowState.height
        )
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = TitlebarTabsWindow(contentRect: rect, styleMask: styleMask, backing: .buffered, defer: false)
        window.title = "mdv"
        window.isReleasedWhenClosed = false

        super.init(window: window)

        setupWebView()
        window.contentView = webView
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "ready")
        contentController.add(self, name: "openExternal")
        contentController.add(self, name: "contextMenu")
        config.userContentController = contentController

        webView = NoBeepWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.onEscape = { [weak self] in
            self?.webView.evaluateJavaScript("window.handleEscape()") { _, _ in }
        }
        #if DEBUG
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        #endif

        guard let resourceURL = Bundle.main.resourceURL else { return }
        let htmlURL = resourceURL.appendingPathComponent("index.html")
        webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: "/"))
    }

    func openFile(path: String) {
        filePath = path
        gitRoot = resolveGitRoot(for: path)
        window?.representedURL = URL(fileURLWithPath: path)
        window?.title = (path as NSString).lastPathComponent

        loadAndSendMarkdown()
        startWatching()
    }

    func reloadFile() {
        loadAndSendMarkdown()
    }

    func buildContextMenuItems(menu: NSMenu) {
        menu.addItem(.separator())

        let pathItem = NSMenuItem(
            title: "Copy Absolute Path",
            action: #selector(copyFullPath(_:)),
            keyEquivalent: ""
        )
        pathItem.target = self
        menu.addItem(pathItem)

        let contentItem = NSMenuItem(
            title: "Copy as Markdown",
            action: #selector(copyContent(_:)),
            keyEquivalent: ""
        )
        contentItem.target = self
        menu.addItem(contentItem)

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

    private func resolveGitRoot(for path: String) -> String? {
        let dir = (path as NSString).deletingLastPathComponent
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", dir, "rev-parse", "--show-toplevel"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func relativePath(for absolutePath: String) -> String {
        guard let root = gitRoot else { return absolutePath }
        let rootPrefix = root.hasSuffix("/") ? root : root + "/"
        if absolutePath.hasPrefix(rootPrefix) {
            return String(absolutePath.dropFirst(rootPrefix.count))
        }
        return absolutePath
    }

    func zoomIn() {
        currentZoom = min(currentZoom + 0.1, 3.0)
        webView.pageZoom = currentZoom
    }

    func zoomOut() {
        currentZoom = max(currentZoom - 0.1, 0.3)
        webView.pageZoom = currentZoom
    }

    func resetZoom() {
        currentZoom = 1.0
        webView.pageZoom = currentZoom
    }

    func performFind() {
        webView.evaluateJavaScript("window.showSearchBar()") { _, error in
            if let error = error {
                NSLog("showSearchBar error: \(error)")
            }
        }
    }

    @objc func toggleToc(_ sender: Any?) {
        webView.evaluateJavaScript("window.toggleToc()") { _, error in
            if let error = error {
                NSLog("toggleToc error: \(error)")
            }
        }
    }

    private func loadAndSendMarkdown() {
        guard let filePath = filePath else { return }

        guard FileManager.default.fileExists(atPath: filePath) else {
            fileWatcher?.stop()
            window?.title = "\((filePath as NSString).lastPathComponent) (削除済み)"
            return
        }

        guard let markdown = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            let alert = NSAlert()
            alert.messageText = "ファイルを読み込めません"
            alert.informativeText = "\(filePath) を開けませんでした"
            alert.alertStyle = .warning
            alert.runModal()
            return
        }
        let basePath = (filePath as NSString).deletingLastPathComponent
        sendMarkdown(markdown, basePath: basePath)
    }

    private func sendMarkdown(_ markdown: String, basePath: String? = nil) {
        guard isReady else {
            pendingMarkdown = markdown
            pendingBasePath = basePath
            return
        }
        guard let jsonData = try? JSONEncoder().encode(markdown),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        let basePathArg: String
        if let basePath = basePath,
           let basePathData = try? JSONEncoder().encode(basePath),
           let basePathJson = String(data: basePathData, encoding: .utf8) {
            basePathArg = basePathJson
        } else {
            basePathArg = "null"
        }
        webView.evaluateJavaScript("window.updateMarkdown(\(jsonString), \(basePathArg))") { _, error in
            if let error = error {
                NSLog("evaluateJavaScript error: \(error)")
            }
        }
    }

    private func startWatching() {
        fileWatcher?.stop()
        guard let filePath = filePath else { return }
        fileWatcher = FileWatcher(filePath: filePath) { [weak self] in
            self?.loadAndSendMarkdown()
        }
        fileWatcher?.start()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "ready":
            isReady = true
            if let pending = pendingMarkdown {
                let basePath = pendingBasePath
                pendingMarkdown = nil
                pendingBasePath = nil
                sendMarkdown(pending, basePath: basePath)
            }
        case "openExternal":
            if let urlString = message.body as? String, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        case "contextMenu":
            if let dict = message.body as? [String: Any] {
                let startLine = dict["startLine"] as? Int
                let endLine = dict["endLine"] as? Int
                if let start = startLine, let end = endLine {
                    cachedLineInfo = LineInfo(startLine: start, endLine: end)
                } else {
                    cachedLineInfo = nil
                }
            } else {
                cachedLineInfo = nil
            }
        default:
            break
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url {
            if url.isFileURL {
                let ext = url.pathExtension.lowercased()
                if (ext == "md" || ext == "markdown") && navigationAction.navigationType == .linkActivated {
                    WindowManager.shared.openOrFocus(filePath: url.path)
                    decisionHandler(.cancel)
                } else {
                    decisionHandler(.allow)
                }
            } else if url.scheme == "http" || url.scheme == "https" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.cancel)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    deinit {
        fileWatcher?.stop()
    }
}

extension MarkdownWindowController: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        onWindowStateChange?(window)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        onWindowStateChange?(window)
    }

    func windowWillClose(_ notification: Notification) {
        fileWatcher?.stop()
        if let path = filePath {
            onWindowClose?(path)
        }
    }
}
