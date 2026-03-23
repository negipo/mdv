import XCTest
@testable import mdv

final class MarkdownWindowControllerTests: XCTestCase {
    private var controller: MarkdownWindowController!

    override func setUp() {
        super.setUp()
        let state = WindowManager.WindowState()
        controller = MarkdownWindowController(windowState: state)
    }

    override func tearDown() {
        controller.window?.orderOut(nil)
        controller.window?.close()
        controller = nil
        super.tearDown()
    }

    // ウィンドウが正しいtabbingIdentifierで作成される
    func testWindowIsCreatedWithCorrectTabbingIdentifier() {
        XCTAssertEqual(controller.window?.tabbingIdentifier, "mdv-markdown")
    }

    // ウィンドウがTitlebarTabsWindowのインスタンスで作成される
    func testWindowIsTitlebarTabsWindow() {
        XCTAssertTrue(controller.window is TitlebarTabsWindow)
    }

    // デフォルトのウィンドウサイズがcontentRectに基づいている
    func testDefaultWindowSize() {
        let window = controller.window!
        let defaultState = WindowManager.WindowState()
        let baseRect = NSRect(x: 0, y: 0, width: CGFloat(defaultState.width), height: CGFloat(defaultState.height))
        let baseFrame = TitlebarTabsWindow.frameRect(forContentRect: baseRect, styleMask: window.styleMask)
        XCTAssertEqual(window.frame.width, baseFrame.width)
    }

    // カスタムWindowStateでウィンドウ幅が反映される
    func testCustomWindowStateSize() {
        let customController = MarkdownWindowController(
            windowState: WindowManager.WindowState(width: 1200, height: 800, x: 50, y: 50)
        )
        defer {
            customController.window?.orderOut(nil)
            customController.window?.close()
        }

        let window = customController.window!
        XCTAssertEqual(window.frame.width, 1200)
        let defaultController = MarkdownWindowController(
            windowState: WindowManager.WindowState(width: 1200, height: 600, x: 50, y: 50)
        )
        defer {
            defaultController.window?.orderOut(nil)
            defaultController.window?.close()
        }
        XCTAssertGreaterThan(window.frame.height, defaultController.window!.frame.height)
    }

    // ファイルを開くとウィンドウタイトルがファイル名になる
    func testOpenFileSetsWindowTitle() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctrl_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: "# Hello".data(using: .utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        controller.openFile(path: tmpFile)
        let expectedTitle = (tmpFile as NSString).lastPathComponent
        XCTAssertEqual(controller.window?.title, expectedTitle)
    }

    // ファイルを開くとrepresentedURLが設定される
    func testOpenFileSetsRepresentedURL() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctrl_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: "# Hello".data(using: .utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        controller.openFile(path: tmpFile)
        XCTAssertEqual(controller.window?.representedURL, URL(fileURLWithPath: tmpFile))
    }

    // ファイルが削除された後にリロードするとタイトルに「削除済み」が付く
    func testDeletedFileUpdatesTitle() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctrl_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: "# Hello".data(using: .utf8))

        controller.openFile(path: tmpFile)
        try? FileManager.default.removeItem(atPath: tmpFile)
        controller.reloadFile()

        XCTAssertTrue(controller.window?.title.contains("削除済み") ?? false)
    }

    // ファイルを開く前はcurrentFilePathがnilを返す
    func testCurrentFilePathReturnsNilBeforeOpen() {
        XCTAssertNil(controller.currentFilePath)
    }

    // ファイルを開くとcurrentFilePathがフルパスを返す
    func testCurrentFilePathReturnsFullPath() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctrl_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: "# Hello".data(using: .utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        controller.openFile(path: tmpFile)
        XCTAssertEqual(controller.currentFilePath, tmpFile)
    }
}
