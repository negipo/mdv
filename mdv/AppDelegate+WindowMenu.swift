import AppKit

// MARK: - Window Menu

extension AppDelegate {
    func buildWindowMenuItem() -> NSMenuItem {
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
