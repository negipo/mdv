import XCTest
@testable import mdv

final class CrossWindowTabTests: XCTestCase {
    /// tabbingMode と tabbingIdentifier が正しく設定される
    func testTitlebarTabsWindowHasCorrectTabbingConfig() {
        let window = TitlebarTabsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        XCTAssertEqual(window.tabbingMode, .preferred)
        XCTAssertEqual(window.tabbingIdentifier, "mdv-markdown")
    }

    /// ウインドウが無い場合は nil を返す
    func testFindTargetWindowReturnsNilWhenNoWindows() {
        let tmpDir = NSTemporaryDirectory() + "mdv_test_\(UUID().uuidString)"
        let manager = WindowManager(configDir: tmpDir)
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        let target = manager.findTargetWindow(excluding: nil)
        XCTAssertNil(target)
    }
}
