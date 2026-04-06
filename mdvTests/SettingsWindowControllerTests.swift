import XCTest
@testable import mdv

final class SettingsWindowControllerTests: XCTestCase {
    private var controller: SettingsWindowController!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "appearance")
        UserDefaults.standard.removeObject(forKey: SendToTerminalAction.defaultsKey)
        controller = SettingsWindowController()
    }

    override func tearDown() {
        controller = nil
        UserDefaults.standard.removeObject(forKey: "appearance")
        UserDefaults.standard.removeObject(forKey: SendToTerminalAction.defaultsKey)
        super.tearDown()
    }

    // ウィンドウタイトルが"Settings"である
    func testWindowTitle() {
        XCTAssertEqual(controller.window?.title, "Settings")
    }

    // デフォルトでsystemが選択されている
    func testDefaultAppearanceIsSystem() {
        XCTAssertEqual(controller.selectedAppearance, "system")
    }

    // セグメントコントロールでdarkを選択するとUserDefaultsに保存される
    func testSelectingDarkSavesToUserDefaults() {
        controller.selectedAppearance = "dark"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "appearance"), "dark")
    }

    // セグメントコントロールでlightを選択するとUserDefaultsに保存される
    func testSelectingLightSavesToUserDefaults() {
        controller.selectedAppearance = "light"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "appearance"), "light")
    }

    func testDefaultSendToTerminalAction() {
        XCTAssertEqual(SendToTerminalAction.current, .pathLineContent)
    }

    func testSendToTerminalActionPersistence() {
        SendToTerminalAction.current = .absolutePath
        XCTAssertEqual(SendToTerminalAction.current, .absolutePath)
    }
}
