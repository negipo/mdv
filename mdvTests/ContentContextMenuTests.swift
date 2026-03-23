import XCTest
@testable import mdv

final class ContentContextMenuTests: XCTestCase {
    // copyFullPathがファイルパスをクリップボードにコピーする
    func testCopyFullPathAction() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctx_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: "# Test".data(using: .utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)

        controller.copyFullPath(nil)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), tmpFile)
    }

    // copyContentがファイル内容をクリップボードにコピーする
    func testCopyContentAction() {
        let content = "# Hello\n\nWorld"
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctx_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: content.data(using: .utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)

        controller.copyContent(nil)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), content)
    }
}
