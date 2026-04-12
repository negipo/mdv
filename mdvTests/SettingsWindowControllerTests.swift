import XCTest
@testable import mdv

final class SettingsWindowControllerTests: XCTestCase {
    private var controller: SettingsWindowController!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "appearance")
        UserDefaults.standard.removeObject(forKey: SendToAppAction.defaultsKey)
        UserDefaults.standard.removeObject(forKey: "sendTargetBundleID")
        UserDefaults.standard.removeObject(forKey: "sendTargetAppName")
        controller = SettingsWindowController()
    }

    override func tearDown() {
        controller = nil
        UserDefaults.standard.removeObject(forKey: "appearance")
        UserDefaults.standard.removeObject(forKey: SendToAppAction.defaultsKey)
        UserDefaults.standard.removeObject(forKey: "sendTargetBundleID")
        UserDefaults.standard.removeObject(forKey: "sendTargetAppName")
        super.tearDown()
    }

    func testWindowTitle() {
        XCTAssertEqual(controller.window?.title, "Settings")
    }

    func testDefaultAppearanceIsSystem() {
        XCTAssertEqual(controller.selectedAppearance, "system")
    }

    func testSelectingDarkSavesToUserDefaults() {
        controller.selectedAppearance = "dark"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "appearance"), "dark")
    }

    func testSelectingLightSavesToUserDefaults() {
        controller.selectedAppearance = "light"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "appearance"), "light")
    }

    func testDefaultSendToAppAction() {
        XCTAssertEqual(SendToAppAction.current, .pathLineContent)
    }

    func testSendToAppActionPersistence() {
        SendToAppAction.current = .absolutePath
        XCTAssertEqual(SendToAppAction.current, .absolutePath)
    }
}
