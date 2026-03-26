import XCTest
@testable import mdv

final class SessionPersistenceTests: XCTestCase {
    private var tmpDir: String!
    private var manager: WindowManager!

    override func setUp() {
        super.setUp()
        tmpDir = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_test_\(UUID().uuidString)")
        manager = WindowManager(configDir: tmpDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: tmpDir)
        super.tearDown()
    }

    // セッションファイルがない場合は空配列を返す
    func testLoadSessionReturnsEmptyWhenNoFile() {
        let restored = manager.loadSession()
        XCTAssertTrue(restored.isEmpty)
    }

    // セッションファイルに書き込んだパスがloadSessionで復元される
    func testSaveAndLoadSessionRoundTrip() {
        let sessionPath = (tmpDir as NSString).appendingPathComponent("session.json")
        let paths = ["/tmp/test1.md", "/tmp/test2.md"]
        // swiftlint:disable:next force_try
        let data = try! JSONEncoder().encode(paths)
        FileManager.default.createFile(atPath: sessionPath, contents: data)

        let restored = manager.loadSession()
        XCTAssertEqual(restored, paths)
    }

    // 壊れたセッションファイルの場合は空配列を返す
    func testLoadSessionReturnsEmptyForCorruptedFile() {
        let sessionPath = (tmpDir as NSString).appendingPathComponent("session.json")
        FileManager.default.createFile(atPath: sessionPath, contents: "not json".data(using: .utf8))

        let restored = manager.loadSession()
        XCTAssertTrue(restored.isEmpty)
    }
}
