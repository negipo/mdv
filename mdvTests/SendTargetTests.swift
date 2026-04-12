import XCTest
@testable import mdv

final class SendTargetTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "sendTargetBundleID")
        UserDefaults.standard.removeObject(forKey: "sendTargetAppName")
        super.tearDown()
    }

    func testDefaultIsNotConfigured() {
        UserDefaults.standard.removeObject(forKey: "sendTargetBundleID")
        XCTAssertFalse(SendTarget.isConfigured)
        XCTAssertNil(SendTarget.bundleID)
        XCTAssertNil(SendTarget.appName)
    }

    func testSetAndGet() {
        SendTarget.bundleID = "com.mitchellh.ghostty"
        SendTarget.appName = "Ghostty"
        XCTAssertTrue(SendTarget.isConfigured)
        XCTAssertEqual(SendTarget.bundleID, "com.mitchellh.ghostty")
        XCTAssertEqual(SendTarget.appName, "Ghostty")
    }

    func testClear() {
        SendTarget.bundleID = "com.mitchellh.ghostty"
        SendTarget.appName = "Ghostty"
        SendTarget.clear()
        XCTAssertFalse(SendTarget.isConfigured)
        XCTAssertNil(SendTarget.bundleID)
        XCTAssertNil(SendTarget.appName)
    }

    func testMenuTitle() {
        SendTarget.bundleID = "com.mitchellh.ghostty"
        SendTarget.appName = "Ghostty"
        XCTAssertEqual(SendTarget.menuTitle, "Send to Ghostty")

        SendTarget.clear()
        XCTAssertEqual(SendTarget.menuTitle, "Send to\u{2026}")
    }
}
