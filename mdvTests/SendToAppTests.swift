import XCTest
@testable import mdv

final class SendToAppTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: SendToAppAction.defaultsKey)
        super.tearDown()
    }

    func testGenerateContentRelativePath() {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path
        let tmpFile = (projectRoot as NSString).appendingPathComponent("tmp/mdv_send_\(UUID().uuidString).md")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: tmpFile).deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: tmpFile, contents: Data("# Test".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)

        let result = controller.generateSendContent(action: .relativePath)
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.hasPrefix("/"))
    }

    func testGenerateContentAbsolutePath() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_send_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: Data("# Test".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)

        let result = controller.generateSendContent(action: .absolutePath)
        XCTAssertEqual(result, tmpFile)
    }

    func testGenerateContentFileAsMarkdown() {
        let content = "# Hello\n\nWorld"
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_send_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: Data(content.utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)

        let result = controller.generateSendContent(action: .fileAsMarkdown)
        XCTAssertEqual(result, content)
    }

    func testGenerateContentRelativePathWithLinesCached() {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path
        let tmpFile = (projectRoot as NSString).appendingPathComponent("tmp/mdv_send_\(UUID().uuidString).md")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: tmpFile).deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: tmpFile, contents: Data("# Test".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)
        controller.cachedLineInfo = MarkdownWindowController.LineInfo(startLine: 3, endLine: 3)

        let result = controller.generateSendContent(action: .relativePathWithLines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.hasSuffix(":3"))
    }

    func testGenerateContentRelativePathWithLinesNoCacheFallback() {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path
        let tmpFile = (projectRoot as NSString).appendingPathComponent("tmp/mdv_send_\(UUID().uuidString).md")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: tmpFile).deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: tmpFile, contents: Data("# Test".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)
        controller.cachedLineInfo = nil

        let result = controller.generateSendContent(action: .relativePathWithLines)
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.contains(":"))
    }
}
