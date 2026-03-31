import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private var pendingFilePaths: [String] = []
    private var isFinishedLaunching = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        isFinishedLaunching = true
        buildMenu()
        promptCLIInstallIfNeeded()
        openInitialFiles()
    }

    func application(_ sender: NSApplication, open urls: [URL]) {
        for url in urls {
            let path = url.path
            if isFinishedLaunching {
                WindowManager.shared.openOrFocus(filePath: path)
            } else {
                pendingFilePaths.append(path)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            WindowManager.shared.showOpenDialog()
        }
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        WindowManager.shared.saveSession()
        return .terminateNow
    }

    private func openInitialFiles() {
        if !pendingFilePaths.isEmpty {
            for path in pendingFilePaths {
                WindowManager.shared.openOrFocus(filePath: path)
            }
            pendingFilePaths.removeAll()
            return
        }

        let args = ProcessInfo.processInfo.arguments
        let filePaths = parseFilePathsFromArgs(args)
        if !filePaths.isEmpty {
            for path in filePaths {
                WindowManager.shared.openOrFocus(filePath: path)
            }
            return
        }

        let sessionFiles = WindowManager.shared.loadSession()
        if !sessionFiles.isEmpty {
            for path in sessionFiles where FileManager.default.fileExists(atPath: path) {
                WindowManager.shared.openOrFocus(filePath: path)
            }
        }
        if WindowManager.shared.windowCount == 0 {
            WindowManager.shared.showOpenDialog()
        }
    }

    private func parseFilePathsFromArgs(_ args: [String]) -> [String] {
        let filtered = args.dropFirst().filter { !$0.hasPrefix("-") }
        return filtered.map { raw in
            let base = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let url = URL(fileURLWithPath: raw, relativeTo: base)
            return url.standardizedFileURL.path
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(reopenClosedTab(_:)) {
            return WindowManager.shared.canReopenLastClosed
        }
        return true
    }

    @objc private func openDocument(_ sender: Any?) {
        WindowManager.shared.showOpenDialog()
    }

    @objc private func reopenClosedTab(_ sender: Any?) {
        WindowManager.shared.reopenLastClosed()
    }

    @objc private func performFindAction(_ sender: Any?) {
        if let window = NSApplication.shared.keyWindow,
           let controller = window.windowController as? MarkdownWindowController {
            controller.performFind()
        }
    }

    @objc private func toggleTableOfContents(_ sender: Any?) {
        if let window = NSApplication.shared.keyWindow,
           let controller = window.windowController as? MarkdownWindowController {
            controller.toggleToc(nil)
        }
    }

    @objc private func reloadContent(_ sender: Any?) {
        if let window = NSApplication.shared.keyWindow,
           let controller = window.windowController as? MarkdownWindowController {
            controller.reloadFile()
        }
    }

    @objc private func zoomIn(_ sender: Any?) {
        if let window = NSApplication.shared.keyWindow,
           let controller = window.windowController as? MarkdownWindowController {
            controller.zoomIn()
        }
    }

    @objc private func zoomOut(_ sender: Any?) {
        if let window = NSApplication.shared.keyWindow,
           let controller = window.windowController as? MarkdownWindowController {
            controller.zoomOut()
        }
    }

    @objc private func resetZoom(_ sender: Any?) {
        if let window = NSApplication.shared.keyWindow,
           let controller = window.windowController as? MarkdownWindowController {
            controller.resetZoom()
        }
    }
}

// MARK: - Menu

extension AppDelegate {
    func buildMenu() {
        let mainMenu = NSMenu()

        mainMenu.addItem(buildAppMenuItem())
        mainMenu.addItem(buildFileMenuItem())
        mainMenu.addItem(buildEditMenuItem())
        mainMenu.addItem(buildViewMenuItem())

        let windowMenuItem = buildWindowMenuItem()
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
        NSApplication.shared.windowsMenu = windowMenuItem.submenu
    }

    private func buildAppMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu()
        menu.addItem(
            withTitle: "About mdv",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: "Install Command Line Tool\u{2026}",
            action: #selector(installCLI(_:)),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(withTitle: "Hide mdv", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = menu.addItem(
            withTitle: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        )
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(
            withTitle: "Show All",
            action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit mdv",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        item.submenu = menu
        return item
    }

    private func buildFileMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "File")
        menu.addItem(withTitle: "Open…", action: #selector(openDocument(_:)), keyEquivalent: "o")
        menu.addItem(.separator())
        let reopenItem = menu.addItem(
            withTitle: "Reopen Closed Tab",
            action: #selector(reopenClosedTab(_:)),
            keyEquivalent: "t"
        )
        reopenItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        item.submenu = menu
        return item
    }

    private func buildEditMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Edit")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Find\u{2026}", action: #selector(performFindAction(_:)), keyEquivalent: "f")
        item.submenu = menu
        return item
    }

    private func buildViewMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "View")
        menu.addItem(withTitle: "Reload", action: #selector(reloadContent(_:)), keyEquivalent: "r")
        menu.addItem(
            withTitle: "Table of Contents",
            action: #selector(toggleTableOfContents(_:)),
            keyEquivalent: "t"
        )
        menu.addItem(.separator())
        menu.addItem(withTitle: "Zoom In", action: #selector(zoomIn(_:)), keyEquivalent: "+")
        menu.addItem(withTitle: "Zoom Out", action: #selector(zoomOut(_:)), keyEquivalent: "-")
        menu.addItem(withTitle: "Actual Size", action: #selector(resetZoom(_:)), keyEquivalent: "0")
        menu.addItem(.separator())
        let fullScreen = menu.addItem(
            withTitle: "Toggle Full Screen",
            action: #selector(NSWindow.toggleFullScreen(_:)),
            keyEquivalent: "f"
        )
        fullScreen.keyEquivalentModifierMask = [.command, .control]
        item.submenu = menu
        return item
    }

    private func buildWindowMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Window")
        menu.addItem(
            withTitle: "Minimize",
            action: #selector(NSWindow.performMiniaturize(_:)),
            keyEquivalent: "m"
        )
        menu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        menu.addItem(.separator())

        let prevTab1 = menu.addItem(
            withTitle: "Show Previous Tab",
            action: #selector(NSWindow.selectPreviousTab(_:)),
            keyEquivalent: "{"
        )
        prevTab1.keyEquivalentModifierMask = [.command]
        let nextTab1 = menu.addItem(
            withTitle: "Show Next Tab",
            action: #selector(NSWindow.selectNextTab(_:)),
            keyEquivalent: "}"
        )
        nextTab1.keyEquivalentModifierMask = [.command]
        let leftArrow = String(Character(UnicodeScalar(NSLeftArrowFunctionKey)!))
        let rightArrow = String(Character(UnicodeScalar(NSRightArrowFunctionKey)!))
        let prevTab2 = menu.addItem(
            withTitle: "Show Previous Tab",
            action: #selector(NSWindow.selectPreviousTab(_:)),
            keyEquivalent: leftArrow
        )
        prevTab2.keyEquivalentModifierMask = [.command, .option]
        prevTab2.isAlternate = true
        let nextTab2 = menu.addItem(
            withTitle: "Show Next Tab",
            action: #selector(NSWindow.selectNextTab(_:)),
            keyEquivalent: rightArrow
        )
        nextTab2.keyEquivalentModifierMask = [.command, .option]
        nextTab2.isAlternate = true

        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Move Tab to New Window",
            action: #selector(NSWindow.moveTabToNewWindow(_:)),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: "Merge All Windows",
            action: #selector(NSWindow.mergeAllWindows(_:)),
            keyEquivalent: ""
        )
        item.submenu = menu
        return item
    }
}

// MARK: - CLI

extension AppDelegate {
    private static let cliInstallPath = "/usr/local/bin/mdv"
    private static let cliSearchPaths = ["/opt/homebrew/bin/mdv", "/usr/local/bin/mdv"]
    private static let cliPromptShownKey = "CLIInstallPromptShown"
    private var installedCLIPath: String? {
        Self.cliSearchPaths.first { path in
            (try? FileManager.default.attributesOfItem(atPath: path)) != nil
        }
    }
    private var isCLIInstalled: Bool { installedCLIPath != nil }

    func promptCLIInstallIfNeeded() {
        if isCLIInstalled { return }
        if UserDefaults.standard.bool(forKey: Self.cliPromptShownKey) { return }

        UserDefaults.standard.set(true, forKey: Self.cliPromptShownKey)

        let alert = NSAlert()
        alert.messageText = "Install command line tool?"
        alert.informativeText = "Would you like to use mdv from the terminal? " +
            "You can also install it later from the mdv menu."
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Not Now")

        if alert.runModal() == .alertFirstButtonReturn {
            performCLIInstall()
        }
    }

    @objc private func installCLI(_ sender: Any?) {
        if isCLIInstalled {
            let alert = NSAlert()
            alert.messageText = "Command line tool is already installed."
            alert.informativeText = "The mdv command is available at \(installedCLIPath ?? Self.cliInstallPath)."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        performCLIInstall()
    }

    private func performCLIInstall() {
        guard let resourcePath = Bundle.main.resourcePath else {
            showInstallFailedAlert(message: "Could not locate app bundle resources.")
            return
        }

        let bundleCLIPath = resourcePath + "/bin/mdv"
        let cmd = "mkdir -p /usr/local/bin && ln -sf '\(bundleCLIPath)' '\(Self.cliInstallPath)'"
        runCLIInstallScript("do shell script \"\(cmd)\" with administrator privileges")
    }

    private func showInstallFailedAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Installation failed."
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func runCLIInstallScript(_ script: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]

            let pipe = Pipe()
            process.standardError = pipe

            do {
                try process.run()
            } catch {
                DispatchQueue.main.async {
                    self.showInstallFailedAlert(message: error.localizedDescription)
                }
                return
            }

            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            DispatchQueue.main.async {
                self.handleInstallResult(process: process, errorData: errorData)
            }
        }
    }

    private func handleInstallResult(process: Process, errorData: Data) {
        if process.terminationStatus == 0 {
            let alert = NSAlert()
            alert.messageText = "Command line tool installed successfully."
            alert.informativeText = "You can now use 'mdv' from the terminal."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } else {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            if errorMessage.contains("User canceled") { return }
            showInstallFailedAlert(message: errorMessage)
        }
    }
}
