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
}
