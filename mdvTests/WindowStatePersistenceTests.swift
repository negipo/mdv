import XCTest
@testable import mdv

final class WindowStatePersistenceTests: XCTestCase {
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

    // ウィンドウ状態ファイルがない場合はデフォルト値を返す
    func testDefaultWindowState() {
        let state = manager.loadWindowState()
        XCTAssertEqual(state.width, 900)
        XCTAssertEqual(state.height, 700)
        XCTAssertNil(state.x)
        XCTAssertNil(state.y)
    }

    // ウィンドウ状態の保存と復元が正しく往復する
    func testSaveAndLoadWindowStateRoundTrip() {
        let statePath = (tmpDir as NSString).appendingPathComponent("window-state.json")
        let state = WindowManager.WindowState(width: 1200, height: 800, x: 100, y: 200)
        // swiftlint:disable:next force_try
        let data = try! JSONEncoder().encode(state)
        FileManager.default.createFile(atPath: statePath, contents: data)

        let loaded = manager.loadWindowState()
        XCTAssertEqual(loaded.width, 1200)
        XCTAssertEqual(loaded.height, 800)
        XCTAssertEqual(loaded.x, 100)
        XCTAssertEqual(loaded.y, 200)
    }

    // 壊れたJSONファイルの場合はデフォルト値にフォールバックする
    func testCorruptedWindowStateReturnsDefault() {
        let statePath = (tmpDir as NSString).appendingPathComponent("window-state.json")
        FileManager.default.createFile(atPath: statePath, contents: Data("not json".utf8))

        let state = manager.loadWindowState()
        XCTAssertEqual(state.width, 900)
        XCTAssertEqual(state.height, 700)
    }

    // positionがnilのJSON（widthとheightのみ）を正しくデコードできる
    func testDecodeWithNilPosition() {
        let statePath = (tmpDir as NSString).appendingPathComponent("window-state.json")
        let json = #"{"width":1000,"height":600}"#
        FileManager.default.createFile(atPath: statePath, contents: json.data(using: .utf8))

        let state = manager.loadWindowState()
        XCTAssertEqual(state.width, 1000)
        XCTAssertEqual(state.height, 600)
        XCTAssertNil(state.x)
        XCTAssertNil(state.y)
    }
}
