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

    // CLIインストール項目がAbout mdvの直後、セパレータの前に配置されている
    func testCLIInstallItemIsAfterAboutAndBeforeSeparator() {
        let mainMenu = NSApplication.shared.mainMenu
        let appMenu = mainMenu?.item(at: 0)?.submenu

        let aboutIndex = appMenu?.indexOfItem(withTitle: "About mdv")
        let cliIndex = appMenu?.indexOfItem(withTitle: "Install Command Line Tool\u{2026}")
        XCTAssertNotNil(aboutIndex)
        XCTAssertNotNil(cliIndex)
        XCTAssertEqual(cliIndex, aboutIndex! + 1)
        XCTAssertTrue(appMenu!.item(at: cliIndex! + 1)!.isSeparatorItem)
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
}
