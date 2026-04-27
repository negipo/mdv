import AppKit
import UniformTypeIdentifiers

class WindowManager {
    static let shared = WindowManager()

    private var controllers: [String: MarkdownWindowController] = [:]
    private let configDir: String
    private let windowStatePath: String
    private let sessionPath: String
    private var closedPaths: [String] = []

    var windowCount: Int { controllers.count }

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mdvDir = appSupport.appendingPathComponent("mdv")
        configDir = mdvDir.path
        windowStatePath = mdvDir.appendingPathComponent("window-state.json").path
        sessionPath = mdvDir.appendingPathComponent("session.json").path

        try? FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
    }

    init(configDir: String) {
        self.configDir = configDir
        self.windowStatePath = (configDir as NSString).appendingPathComponent("window-state.json")
        self.sessionPath = (configDir as NSString).appendingPathComponent("session.json")

        try? FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
    }

    func openOrFocus(filePath: String) {
        let resolved = URL(fileURLWithPath: filePath).resolvingSymlinksInPath().path

        guard FileManager.default.fileExists(atPath: resolved) else {
            let alert = NSAlert()
            alert.messageText = "ファイルを開けません"
            alert.informativeText = "\(filePath) が見つかりません"
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        if let existing = controllers[resolved] {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let state = loadWindowState()
        let controller = MarkdownWindowController(windowState: state)
        controller.onWindowClose = { [weak self] path in
            self?.closedPaths.append(path)
            self?.controllers.removeValue(forKey: path)
        }
        controller.onWindowStateChange = { [weak self] window in
            self?.debouncedSaveWindowState(for: window)
        }
        controllers[resolved] = controller
        controller.openFile(path: resolved)

        if let existingWindow = findTargetWindow(excluding: controller),
           let newWindow = controller.window {
            existingWindow.addTabbedWindow(newWindow, ordered: .above)
            newWindow.makeKeyAndOrderFront(nil)
        } else {
            controller.showWindow(nil)
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func reopenLastClosed() {
        guard let path = closedPaths.popLast() else { return }
        openOrFocus(filePath: path)
    }

    var canReopenLastClosed: Bool {
        !closedPaths.isEmpty
    }

    func showOpenDialog() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText
        ]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if let controller = NSApplication.shared.keyWindow?.windowController as? MarkdownWindowController,
           let path = controller.filePath {
            panel.directoryURL = URL(fileURLWithPath: (path as NSString).deletingLastPathComponent)
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK {
            for url in panel.urls {
                openOrFocus(filePath: url.path)
            }
        }
    }

    func findTargetWindow(excluding controller: MarkdownWindowController?) -> NSWindow? {
        if let keyWindow = NSApplication.shared.keyWindow,
           keyWindow.tabbingIdentifier == "mdv-markdown",
           let keyController = keyWindow.windowController as? MarkdownWindowController,
           keyController !== controller {
            return keyWindow
        }

        return controllers.values
            .first(where: { $0 !== controller && $0.window?.tabbingIdentifier == "mdv-markdown" })?
            .window
    }

    struct WindowState: Codable {
        var width: CGFloat = 900
        var height: CGFloat = 700
        // swiftlint:disable identifier_name
        var x: CGFloat?
        var y: CGFloat?
        // swiftlint:enable identifier_name
    }

    func loadWindowState() -> WindowState {
        guard let data = FileManager.default.contents(atPath: windowStatePath),
              let state = try? JSONDecoder().decode(WindowState.self, from: data) else {
            return WindowState()
        }
        return state
    }

    private var saveTimer: DispatchSourceTimer?

    private func debouncedSaveWindowState(for window: NSWindow) {
        saveTimer?.cancel()
        let frame = window.frame
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 0.5)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let state = WindowState(width: frame.width, height: frame.height, x: frame.origin.x, y: frame.origin.y)
            if let data = try? JSONEncoder().encode(state) {
                FileManager.default.createFile(atPath: self.windowStatePath, contents: data)
            }
        }
        timer.resume()
        saveTimer = timer
    }

    func saveSession() {
        let paths = Array(controllers.keys)
        if let data = try? JSONEncoder().encode(paths) {
            FileManager.default.createFile(atPath: sessionPath, contents: data)
        }
    }

    func applyThemeToAllWindows(theme: String) {
        for controller in controllers.values {
            controller.applyTheme(theme)
        }
    }

    func loadSession() -> [String] {
        guard let data = FileManager.default.contents(atPath: sessionPath),
              let paths = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return paths
    }
}
