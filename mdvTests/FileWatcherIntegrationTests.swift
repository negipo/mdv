import XCTest
@testable import mdv

final class FileWatcherIntegrationTests: XCTestCase {
    // ファイルの変更を検出してコールバックが発火する
    func testDetectsFileChange() {
        let tmpDir = NSTemporaryDirectory()
        let filePath = (tmpDir as NSString).appendingPathComponent("mdv_test_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: filePath, contents: Data("# Initial".utf8))
        defer { try? FileManager.default.removeItem(atPath: filePath) }

        let callbackFired = expectation(description: "FileWatcher callback fires on file change")
        let watcher = FileWatcher(filePath: filePath, debounceInterval: 0.05) {
            callbackFired.fulfill()
        }
        watcher.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            try? "# Updated".write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        waitForExpectations(timeout: 3.0)
        watcher.stop()
    }

    // stopした後はファイル変更してもコールバックが発火しない
    func testStopPreventsCallback() {
        let tmpDir = NSTemporaryDirectory()
        let filePath = (tmpDir as NSString).appendingPathComponent("mdv_test_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: filePath, contents: Data("# Initial".utf8))
        defer { try? FileManager.default.removeItem(atPath: filePath) }

        var callbackCalled = false
        let watcher = FileWatcher(filePath: filePath, debounceInterval: 0.05) {
            callbackCalled = true
        }
        watcher.start()
        watcher.stop()

        try? "# Updated".write(toFile: filePath, atomically: true, encoding: .utf8)

        let waited = expectation(description: "wait for potential callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            waited.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        XCTAssertFalse(callbackCalled)
    }
}
