import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private var pendingFilePaths: [String] = []
    private var isFinishedLaunching = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        isFinishedLaunching = true
        buildMenu()

        if !pendingFilePaths.isEmpty {
            for path in pendingFilePaths {
                WindowManager.shared.openOrFocus(filePath: path)
            }
            pendingFilePaths.removeAll()
        } else {
            let args = ProcessInfo.processInfo.arguments
            let filePaths = parseFilePathsFromArgs(args)
            if !filePaths.isEmpty {
                for path in filePaths {
                    WindowManager.shared.openOrFocus(filePath: path)
                }
            } else {
                let sessionFiles = WindowManager.shared.loadSession()
                if !sessionFiles.isEmpty {
                    for path in sessionFiles {
                        if FileManager.default.fileExists(atPath: path) {
                            WindowManager.shared.openOrFocus(filePath: path)
                        }
                    }
                }
                if WindowManager.shared.windowCount == 0 {
                    WindowManager.shared.showOpenDialog()
                }
            }
        }
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

    private func parseFilePathsFromArgs(_ args: [String]) -> [String] {
        let filtered = args.dropFirst().filter { !$0.hasPrefix("-") }
        return filtered.map { raw in
            let url = URL(fileURLWithPath: raw, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
            return url.standardizedFileURL.path
        }
    }

    func buildMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About mdv", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(withTitle: "Install Command Line Tool\u{2026}", action: #selector(installCLI(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide mdv", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit mdv", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Open…", action: #selector(openDocument(_:)), keyEquivalent: "o")
        fileMenu.addItem(.separator())
        let reopenItem = fileMenu.addItem(withTitle: "Reopen Closed Tab", action: #selector(reopenClosedTab(_:)), keyEquivalent: "t")
        reopenItem.keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Reload", action: #selector(reloadContent(_:)), keyEquivalent: "r")
        viewMenu.addItem(.separator())
        viewMenu.addItem(withTitle: "Zoom In", action: #selector(zoomIn(_:)), keyEquivalent: "+")
        viewMenu.addItem(withTitle: "Zoom Out", action: #selector(zoomOut(_:)), keyEquivalent: "-")
        viewMenu.addItem(withTitle: "Actual Size", action: #selector(resetZoom(_:)), keyEquivalent: "0")
        viewMenu.addItem(.separator())
        let fullScreen = viewMenu.addItem(withTitle: "Toggle Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullScreen.keyEquivalentModifierMask = [.command, .control]
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(.separator())

        let prevTab1 = windowMenu.addItem(withTitle: "Show Previous Tab", action: #selector(NSWindow.selectPreviousTab(_:)), keyEquivalent: "{")
        prevTab1.keyEquivalentModifierMask = [.command]

        let nextTab1 = windowMenu.addItem(withTitle: "Show Next Tab", action: #selector(NSWindow.selectNextTab(_:)), keyEquivalent: "}")
        nextTab1.keyEquivalentModifierMask = [.command]

        let leftArrow = String(Character(UnicodeScalar(NSLeftArrowFunctionKey)!))
        let rightArrow = String(Character(UnicodeScalar(NSRightArrowFunctionKey)!))

        let prevTab2 = windowMenu.addItem(withTitle: "Show Previous Tab", action: #selector(NSWindow.selectPreviousTab(_:)), keyEquivalent: leftArrow)
        prevTab2.keyEquivalentModifierMask = [.command, .option]
        prevTab2.isAlternate = true

        let nextTab2 = windowMenu.addItem(withTitle: "Show Next Tab", action: #selector(NSWindow.selectNextTab(_:)), keyEquivalent: rightArrow)
        nextTab2.keyEquivalentModifierMask = [.command, .option]
        nextTab2.isAlternate = true

        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Move Tab to New Window", action: #selector(NSWindow.moveTabToNewWindow(_:)), keyEquivalent: "")
        windowMenu.addItem(withTitle: "Merge All Windows", action: #selector(NSWindow.mergeAllWindows(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
        NSApplication.shared.windowsMenu = windowMenu
    }

    @objc private func installCLI(_ sender: Any?) {
    }

    @objc private func openDocument(_ sender: Any?) {
        WindowManager.shared.showOpenDialog()
    }

    @objc private func reopenClosedTab(_ sender: Any?) {
        WindowManager.shared.reopenLastClosed()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(reopenClosedTab(_:)) {
            return WindowManager.shared.canReopenLastClosed
        }
        return true
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
