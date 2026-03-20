import AppKit
import WebKit

class MarkdownWindowController: NSWindowController, WKScriptMessageHandler, WKNavigationDelegate {
    private var webView: WKWebView!
    private var fileWatcher: FileWatcher?
    private var filePath: String?
    private var isReady = false
    private var pendingMarkdown: String?
    private var currentZoom: CGFloat = 1.0

    var onWindowClose: ((String) -> Void)?
    var onWindowStateChange: (() -> Void)?

    init(windowState: WindowManager.WindowState) {
        let rect = NSRect(
            x: windowState.x ?? 200,
            y: windowState.y ?? 200,
            width: windowState.width,
            height: windowState.height
        )
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(contentRect: rect, styleMask: styleMask, backing: .buffered, defer: false)
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
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        #if DEBUG
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        #endif

        guard let resourceURL = Bundle.main.resourceURL else { return }
        let htmlURL = resourceURL.appendingPathComponent("index.html")
        webView.loadFileURL(htmlURL, allowingReadAccessTo: resourceURL)
    }

    func openFile(path: String) {
        filePath = path
        window?.representedURL = URL(fileURLWithPath: path)
        window?.title = "mdv - \((path as NSString).lastPathComponent)"

        loadAndSendMarkdown()
        startWatching()
    }

    func reloadFile() {
        loadAndSendMarkdown()
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

    private func loadAndSendMarkdown() {
        guard let filePath = filePath else { return }

        guard FileManager.default.fileExists(atPath: filePath) else {
            fileWatcher?.stop()
            window?.title = "mdv - \((filePath as NSString).lastPathComponent) (削除済み)"
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
        sendMarkdown(markdown)
    }

    private func sendMarkdown(_ markdown: String) {
        guard isReady else {
            pendingMarkdown = markdown
            return
        }
        guard let jsonData = try? JSONEncoder().encode(markdown),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.updateMarkdown(\(jsonString))") { _, error in
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
                pendingMarkdown = nil
                sendMarkdown(pending)
            }
        case "openExternal":
            if let urlString = message.body as? String, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        default:
            break
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if url.isFileURL {
                decisionHandler(.allow)
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
        onWindowStateChange?()
    }

    func windowDidMove(_ notification: Notification) {
        onWindowStateChange?()
    }

    func windowWillClose(_ notification: Notification) {
        fileWatcher?.stop()
        if let path = filePath {
            onWindowClose?(path)
        }
    }
}
