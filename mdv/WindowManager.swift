import AppKit
import UniformTypeIdentifiers

class WindowManager {
    static let shared = WindowManager()

    private var controllers: [String: MarkdownWindowController] = [:]
    private let configDir: String
    private let windowStatePath: String
    private let sessionPath: String

    var windowCount: Int { controllers.count }

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mdvDir = appSupport.appendingPathComponent("mdv")
        configDir = mdvDir.path
        windowStatePath = mdvDir.appendingPathComponent("window-state.json").path
        sessionPath = mdvDir.appendingPathComponent("session.json").path

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
            self?.controllers.removeValue(forKey: path)
        }
        controller.onWindowStateChange = { [weak self] in
            self?.debouncedSaveWindowState()
        }
        controllers[resolved] = controller
        controller.openFile(path: resolved)
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func showOpenDialog() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        NSApplication.shared.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            openOrFocus(filePath: url.path)
        }
    }

    struct WindowState: Codable {
        var width: CGFloat = 900
        var height: CGFloat = 700
        var x: CGFloat?
        var y: CGFloat?
    }

    func loadWindowState() -> WindowState {
        guard let data = FileManager.default.contents(atPath: windowStatePath),
              let state = try? JSONDecoder().decode(WindowState.self, from: data) else {
            return WindowState()
        }
        return state
    }

    private var saveTimer: DispatchSourceTimer?

    private func debouncedSaveWindowState() {
        saveTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 0.5)
        timer.setEventHandler { [weak self] in
            self?.saveCurrentWindowState()
        }
        timer.resume()
        saveTimer = timer
    }

    private func saveCurrentWindowState() {
        guard let keyWindow = NSApplication.shared.keyWindow,
              let _ = keyWindow.windowController as? MarkdownWindowController else { return }
        let frame = keyWindow.frame
        let state = WindowState(width: frame.width, height: frame.height, x: frame.origin.x, y: frame.origin.y)
        if let data = try? JSONEncoder().encode(state) {
            FileManager.default.createFile(atPath: windowStatePath, contents: data)
        }
    }

    func saveSession() {
        let paths = Array(controllers.keys)
        if let data = try? JSONEncoder().encode(paths) {
            FileManager.default.createFile(atPath: sessionPath, contents: data)
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
