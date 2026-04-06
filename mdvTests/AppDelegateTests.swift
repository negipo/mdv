import XCTest
@testable import mdv

final class AppDelegateTests: XCTestCase {
    private var appDelegate: AppDelegate!

    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
        appDelegate.buildMenu()
    }

    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }

    // アプリケーションメニューにCLIインストール項目が含まれている
    func testAppMenuContainsCLIInstallItem() {
        let mainMenu = NSApplication.shared.mainMenu
        let appMenu = mainMenu?.item(at: 0)?.submenu

        let cliItem = appMenu?.items.first { $0.title == "Install Command Line Tool\u{2026}" }
        XCTAssertNotNil(cliItem, "CLI install menu item should exist in app menu")
    }

    // CLIインストール項目がAbout mdvの直後に配置されている
    func testCLIInstallItemIsAfterAbout() {
        let mainMenu = NSApplication.shared.mainMenu
        let appMenu = mainMenu?.item(at: 0)?.submenu

        let aboutIndex = appMenu?.indexOfItem(withTitle: "About mdv")
        let cliIndex = appMenu?.indexOfItem(withTitle: "Install Command Line Tool\u{2026}")
        XCTAssertNotNil(aboutIndex)
        XCTAssertNotNil(cliIndex)
        XCTAssertEqual(cliIndex, aboutIndex! + 1)
    }

    // Editメニューに標準的なテキスト編集アイテムが含まれている
    func testEditMenuContainsStandardTextEditingItems() {
        let mainMenu = NSApplication.shared.mainMenu
        let editMenu = mainMenu?.items.first { $0.submenu?.title == "Edit" }?.submenu

        XCTAssertNotNil(editMenu, "Edit menu should exist")

        let titles = editMenu!.items.compactMap { $0.isSeparatorItem ? nil : $0.title }
        XCTAssertTrue(titles.contains("Undo"), "Edit menu should contain Undo")
        XCTAssertTrue(titles.contains("Redo"), "Edit menu should contain Redo")
        XCTAssertTrue(titles.contains("Cut"), "Edit menu should contain Cut")
        XCTAssertTrue(titles.contains("Copy"), "Edit menu should contain Copy")
        XCTAssertTrue(titles.contains("Paste"), "Edit menu should contain Paste")
        XCTAssertTrue(titles.contains("Select All"), "Edit menu should contain Select All")
    }

    // アプリメニューにSettings項目が含まれている
    func testAppMenuContainsSettingsItem() {
        let mainMenu = NSApplication.shared.mainMenu
        let appMenu = mainMenu?.item(at: 0)?.submenu

        let settingsItem = appMenu?.items.first { $0.title == "Settings\u{2026}" }
        XCTAssertNotNil(settingsItem, "Settings menu item should exist in app menu")
        XCTAssertEqual(settingsItem?.keyEquivalent, ",")
    }

    // Settings項目がInstall CLI項目の直後に配置されている
    func testSettingsItemIsAfterCLIInstall() {
        let mainMenu = NSApplication.shared.mainMenu
        let appMenu = mainMenu?.item(at: 0)?.submenu

        let cliIndex = appMenu?.indexOfItem(withTitle: "Install Command Line Tool\u{2026}")
        let settingsIndex = appMenu?.indexOfItem(withTitle: "Settings\u{2026}")
        XCTAssertNotNil(cliIndex)
        XCTAssertNotNil(settingsIndex)
        XCTAssertEqual(settingsIndex, cliIndex! + 1)
    }

    // Editメニューのアイテムが標準的なmacOSの順序で並んでいる
    func testEditMenuItemOrder() {
        let mainMenu = NSApplication.shared.mainMenu
        let editMenu = mainMenu?.items.first { $0.submenu?.title == "Edit" }?.submenu

        XCTAssertNotNil(editMenu)

        let nonSeparatorItems = editMenu!.items.filter { !$0.isSeparatorItem }
        let titles = nonSeparatorItems.map { $0.title }

        let undoIndex = titles.firstIndex(of: "Undo")!
        let redoIndex = titles.firstIndex(of: "Redo")!
        let cutIndex = titles.firstIndex(of: "Cut")!
        let copyIndex = titles.firstIndex(of: "Copy")!
        let pasteIndex = titles.firstIndex(of: "Paste")!

        XCTAssertTrue(undoIndex < redoIndex, "Undo should come before Redo")
        XCTAssertTrue(redoIndex < cutIndex, "Redo should come before Cut")
        XCTAssertTrue(cutIndex < copyIndex, "Cut should come before Copy")
        XCTAssertTrue(copyIndex < pasteIndex, "Copy should come before Paste")
    }

    // EditメニューにCopyサブメニューが含まれている
    func testEditMenuContainsCopySubmenu() {
        let mainMenu = NSApplication.shared.mainMenu
        let editMenu = mainMenu?.items.first { $0.submenu?.title == "Edit" }?.submenu

        XCTAssertNotNil(editMenu)
        let copySubmenuItem = editMenu?.items.first { $0.submenu?.title == "Copy" }
        XCTAssertNotNil(copySubmenuItem, "Edit menu should contain a Copy submenu")
    }

    // Copyサブメニューに全5項目が含まれている
    func testCopySubmenuContainsAllItems() {
        let mainMenu = NSApplication.shared.mainMenu
        let editMenu = mainMenu?.items.first { $0.submenu?.title == "Edit" }?.submenu
        let copyMenu = editMenu?.items.first { $0.submenu?.title == "Copy" }?.submenu

        XCTAssertNotNil(copyMenu)
        let titles = copyMenu!.items.compactMap { $0.isSeparatorItem ? nil : $0.title }
        XCTAssertTrue(titles.contains("Copy Path:Line + Content"))
        XCTAssertTrue(titles.contains("Copy Relative Path with Lines"))
        XCTAssertTrue(titles.contains("Copy Relative Path"))
        XCTAssertTrue(titles.contains("Copy File as Markdown"))
        XCTAssertTrue(titles.contains("Copy Absolute Path"))
    }

    // Copyサブメニューのショートカットが正しく設定されている
    func testCopySubmenuShortcuts() {
        let mainMenu = NSApplication.shared.mainMenu
        let editMenu = mainMenu?.items.first { $0.submenu?.title == "Edit" }?.submenu
        let copyMenu = editMenu?.items.first { $0.submenu?.title == "Copy" }?.submenu

        XCTAssertNotNil(copyMenu)

        let pathLineContent = copyMenu?.items.first { $0.title == "Copy Path:Line + Content" }
        XCTAssertEqual(pathLineContent?.keyEquivalent, "l")
        XCTAssertEqual(pathLineContent?.keyEquivalentModifierMask, [.command])

        let relWithLines = copyMenu?.items.first { $0.title == "Copy Relative Path with Lines" }
        XCTAssertEqual(relWithLines?.keyEquivalent, "l")
        XCTAssertEqual(relWithLines?.keyEquivalentModifierMask, [.command, .shift])

        let relPath = copyMenu?.items.first { $0.title == "Copy Relative Path" }
        XCTAssertEqual(relPath?.keyEquivalent, "c")
        XCTAssertEqual(relPath?.keyEquivalentModifierMask, [.command, .shift])

        let fileMarkdown = copyMenu?.items.first { $0.title == "Copy File as Markdown" }
        XCTAssertEqual(fileMarkdown?.keyEquivalent, "m")
        XCTAssertEqual(fileMarkdown?.keyEquivalentModifierMask, [.command, .shift])

        let absPath = copyMenu?.items.first { $0.title == "Copy Absolute Path" }
        XCTAssertEqual(absPath?.keyEquivalent, "c")
        XCTAssertEqual(absPath?.keyEquivalentModifierMask, [.command, .option, .shift])
    }
}
