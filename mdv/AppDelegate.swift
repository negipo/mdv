import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private var pendingFilePaths: [String] = []
    private var isFinishedLaunching = false
    private var settingsController: SettingsWindowController?
    private var appearanceObservation: NSKeyValueObservation?

    func applicationDidFinishLaunching(_ notification: Notification) {
        isFinishedLaunching = true
        buildMenu()
        startObservingAppearance()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appearanceSettingChanged),
            name: SettingsWindowController.appearanceChangedNotification,
            object: nil
        )
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

        let copyActions: [Selector] = [
            #selector(copyFileAsMarkdownAction(_:)),
            #selector(copyRelativePathAction(_:)),
            #selector(copyAbsolutePathAction(_:)),
            #selector(copyRelativePathWithLinesAction(_:)),
            #selector(copyPathLineContentAction(_:)),
            #selector(sendToTerminalAction(_:))
        ]

        if let action = menuItem.action, copyActions.contains(action) {
            guard let window = NSApplication.shared.keyWindow,
                  let controller = window.windowController as? MarkdownWindowController else {
                return false
            }
            return controller.filePath != nil
        }

        return true
    }

    func resolvedTheme() -> String {
        let pref = UserDefaults.standard.string(forKey: SettingsWindowController.appearanceKey) ?? "system"
        switch pref {
        case "light":
            return "light"
        case "dark":
            return "dark"
        default:
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? "dark" : "light"
        }
    }

    private func startObservingAppearance() {
        appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
            guard let self = self else { return }
            let pref = UserDefaults.standard.string(forKey: SettingsWindowController.appearanceKey) ?? "system"
            if pref == "system" {
                WindowManager.shared.applyThemeToAllWindows(theme: self.resolvedTheme())
            }
        }
    }

    @objc private func appearanceSettingChanged() {
        WindowManager.shared.applyThemeToAllWindows(theme: resolvedTheme())
    }

    @objc private func openSettings(_ sender: Any?) {
        if settingsController == nil {
            settingsController = SettingsWindowController()
        }
        settingsController?.showWindow(nil)
        settingsController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func openDocument(_ sender: Any?) {
        WindowManager.shared.showOpenDialog()
    }

    @objc private func reopenClosedTab(_ sender: Any?) {
        WindowManager.shared.reopenLastClosed()
    }

    private func withKeyWindowController(_ body: (MarkdownWindowController) -> Void) {
        if let window = NSApplication.shared.keyWindow,
           let controller = window.windowController as? MarkdownWindowController {
            body(controller)
        }
    }

    @objc private func performFindAction(_ sender: Any?) {
        withKeyWindowController { $0.performFind() }
    }

    @objc private func toggleTableOfContents(_ sender: Any?) {
        withKeyWindowController { $0.toggleToc(nil) }
    }

    @objc private func reloadContent(_ sender: Any?) {
        withKeyWindowController { $0.reloadFile() }
    }

    @objc private func zoomIn(_ sender: Any?) {
        withKeyWindowController { $0.zoomIn() }
    }

    @objc private func zoomOut(_ sender: Any?) {
        withKeyWindowController { $0.zoomOut() }
    }

    @objc private func resetZoom(_ sender: Any?) {
        withKeyWindowController { $0.resetZoom() }
    }

    @objc private func copyFileAsMarkdownAction(_ sender: Any?) {
        withKeyWindowController { $0.copyContent(nil) }
    }

    @objc private func copyRelativePathAction(_ sender: Any?) {
        withKeyWindowController { $0.copyRelativePath(nil) }
    }

    @objc private func copyRelativePathWithLinesAction(_ sender: Any?) {
        withKeyWindowController { $0.performCopyRelativePathWithLines(nil) }
    }

    @objc private func copyAbsolutePathAction(_ sender: Any?) {
        withKeyWindowController { $0.copyFullPath(nil) }
    }

    @objc private func copyPathLineContentAction(_ sender: Any?) {
        withKeyWindowController { $0.performCopyRelativePathWithLinesAndContent(nil) }
    }

    @objc private func sendToTerminalAction(_ sender: Any?) {
        withKeyWindowController { $0.sendToTerminal() }
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
        menu.addItem(
            withTitle: "Settings\u{2026}",
            action: #selector(openSettings(_:)),
            keyEquivalent: ","
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
        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redoItem = menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(.separator())
        menu.addItem(buildCopySubmenuItem())
        let sendItem = menu.addItem(
            withTitle: "Send to Ghostty",
            action: #selector(sendToTerminalAction(_:)),
            keyEquivalent: "g"
        )
        sendItem.keyEquivalentModifierMask = [.command]
        menu.addItem(.separator())
        menu.addItem(withTitle: "Find\u{2026}", action: #selector(performFindAction(_:)), keyEquivalent: "f")
        item.submenu = menu
        return item
    }

    private func buildCopySubmenuItem() -> NSMenuItem {
        let copySubmenuItem = NSMenuItem()
        copySubmenuItem.title = "Copy"
        let copyMenu = NSMenu(title: "Copy")

        let relPathItem = copyMenu.addItem(
            withTitle: "Copy Relative Path",
            action: #selector(copyRelativePathAction(_:)),
            keyEquivalent: "c"
        )
        relPathItem.keyEquivalentModifierMask = [.command, .shift]
        let relLinesItem = copyMenu.addItem(
            withTitle: "Copy Relative Path with Lines",
            action: #selector(copyRelativePathWithLinesAction(_:)),
            keyEquivalent: "l"
        )
        relLinesItem.keyEquivalentModifierMask = [.command, .shift]
        let pathLineContentItem = copyMenu.addItem(
            withTitle: "Copy Path:Line + Content",
            action: #selector(copyPathLineContentAction(_:)),
            keyEquivalent: "l"
        )
        pathLineContentItem.keyEquivalentModifierMask = [.command]
        let absPathItem = copyMenu.addItem(
            withTitle: "Copy Absolute Path",
            action: #selector(copyAbsolutePathAction(_:)),
            keyEquivalent: "c"
        )
        absPathItem.keyEquivalentModifierMask = [.command, .option, .shift]
        copyMenu.addItem(.separator())
        let markdownItem = copyMenu.addItem(
            withTitle: "Copy File as Markdown",
            action: #selector(copyFileAsMarkdownAction(_:)),
            keyEquivalent: "m"
        )
        markdownItem.keyEquivalentModifierMask = [.command, .shift]

        copySubmenuItem.submenu = copyMenu
        return copySubmenuItem
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

}
