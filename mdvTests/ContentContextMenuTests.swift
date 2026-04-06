import XCTest
@testable import mdv

final class ContentContextMenuTests: XCTestCase {
    // copyFullPathがファイルパスをクリップボードにコピーする
    func testCopyFullPathAction() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctx_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: Data("# Test".utf8))
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

    // gitリポジトリ内ファイルのcopyRelativePathが相対パスをコピーする
    func testCopyRelativePathInGitRepo() {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path
        let tmpFile = (projectRoot as NSString).appendingPathComponent("tmp/mdv_ctx_\(UUID().uuidString).md")
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

        controller.copyRelativePath(nil)

        let result = NSPasteboard.general.string(forType: .string) ?? ""
        XCTAssertFalse(result.hasPrefix("/"), "Should be a relative path, got: \(result)")
    }

    // gitリポジトリ外ファイルのcopyRelativePathがフルパスにフォールバックする
    func testCopyRelativePathOutsideGitRepo() {
        let tmpDir = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_nogit_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)
        let tmpFile = (tmpDir as NSString).appendingPathComponent("test.md")
        FileManager.default.createFile(atPath: tmpFile, contents: Data("# Test".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)

        controller.copyRelativePath(nil)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), tmpFile)
    }

    // copyRelativePathWithLinesが行番号付きパスをコピーする（単一行）
    func testCopyRelativePathWithLinesSingleLine() {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path
        let tmpFile = (projectRoot as NSString).appendingPathComponent("tmp/mdv_ctx_\(UUID().uuidString).md")
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

        controller.cachedLineInfo = MarkdownWindowController.LineInfo(startLine: 5, endLine: 5)
        controller.copyRelativePathWithLines(nil)

        let result = NSPasteboard.general.string(forType: .string) ?? ""
        XCTAssertTrue(result.hasSuffix(":5"), "Expected ':5' suffix, got: \(result)")
    }

    // copyRelativePathWithLinesが行番号付きパスをコピーする（範囲）
    func testCopyRelativePathWithLinesRange() {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path
        let tmpFile = (projectRoot as NSString).appendingPathComponent("tmp/mdv_ctx_\(UUID().uuidString).md")
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

        controller.cachedLineInfo = MarkdownWindowController.LineInfo(startLine: 10, endLine: 25)
        controller.copyRelativePathWithLines(nil)

        let result = NSPasteboard.general.string(forType: .string) ?? ""
        XCTAssertTrue(result.hasSuffix(":10-25"), "Expected ':10-25' suffix, got: \(result)")
    }

    // 右クリックメニューにすべてのコピー項目が表示される
    func testContextMenuContainsAllCopyItems() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctx_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: Data("# Test".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)

        let menu = NSMenu()
        controller.buildContextMenuItems(menu: menu)

        let titles = menu.items.map { $0.title }
        XCTAssertTrue(titles.contains("Copy Absolute Path"))
        XCTAssertTrue(titles.contains("Copy File as Markdown"))
        XCTAssertTrue(titles.contains("Copy Relative Path"))
    }

    // cachedLineInfoがある場合、Copy Relative Path with Linesが表示される
    func testContextMenuShowsRelativePathWithLinesWhenLineInfoAvailable() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctx_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: Data("# Test".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)

        controller.cachedLineInfo = MarkdownWindowController.LineInfo(startLine: 1, endLine: 1)
        let menu = NSMenu()
        controller.buildContextMenuItems(menu: menu)

        let titles = menu.items.map { $0.title }
        XCTAssertTrue(titles.contains("Copy Relative Path with Lines"))
    }

    // cachedLineInfoがない場合、Copy Relative Path with Linesが表示されない
    func testContextMenuHidesRelativePathWithLinesWhenNoLineInfo() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctx_\(UUID().uuidString).md")
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
        let menu = NSMenu()
        controller.buildContextMenuItems(menu: menu)

        let titles = menu.items.map { $0.title }
        XCTAssertFalse(titles.contains("Copy Relative Path with Lines"))
    }

    // copyRelativePathWithLinesAndContentが単一行選択時に正しいフォーマットでコピーする
    func testCopyRelativePathWithLinesAndContentSingleLine() {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path
        let tmpFile = (projectRoot as NSString).appendingPathComponent("tmp/mdv_ctx_\(UUID().uuidString).md")
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

        controller.cachedLineInfo = MarkdownWindowController.LineInfo(startLine: 5, endLine: 5)
        controller.copyRelativePathWithLinesAndContent(nil, selectedText: "hello world")

        let result = NSPasteboard.general.string(forType: .string) ?? ""
        let rel = controller.relativePath(for: tmpFile)
        XCTAssertEqual(result, "\(rel):5 hello world")
    }

    // copyRelativePathWithLinesAndContentが複数行選択時に正しいフォーマットでコピーする
    func testCopyRelativePathWithLinesAndContentMultiLine() {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path
        let tmpFile = (projectRoot as NSString).appendingPathComponent("tmp/mdv_ctx_\(UUID().uuidString).md")
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

        controller.cachedLineInfo = MarkdownWindowController.LineInfo(startLine: 10, endLine: 25)
        controller.copyRelativePathWithLinesAndContent(nil, selectedText: "line1\nline2")

        let result = NSPasteboard.general.string(forType: .string) ?? ""
        let rel = controller.relativePath(for: tmpFile)
        XCTAssertEqual(result, "\(rel):10-25\nline1\nline2")
    }

    // cachedLineInfoがある場合、Copy Path:Line + Contentが表示される
    func testContextMenuShowsPathLineContentWhenLineInfoAvailable() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctx_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: Data("# Test".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let state = WindowManager.WindowState()
        let controller = MarkdownWindowController(windowState: state)
        defer {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controller.openFile(path: tmpFile)

        controller.cachedLineInfo = MarkdownWindowController.LineInfo(startLine: 1, endLine: 1)
        let menu = NSMenu()
        controller.buildContextMenuItems(menu: menu)

        let titles = menu.items.map { $0.title }
        XCTAssertTrue(titles.contains("Copy Path:Line + Content"))
    }

    // cachedLineInfoがない場合、Copy Path:Line + Contentが表示されない
    func testContextMenuHidesPathLineContentWhenNoLineInfo() {
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctx_\(UUID().uuidString).md")
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
        let menu = NSMenu()
        controller.buildContextMenuItems(menu: menu)

        let titles = menu.items.map { $0.title }
        XCTAssertFalse(titles.contains("Copy Path:Line + Content"))
    }

    // copyContentがファイル内容をクリップボードにコピーする
    func testCopyContentAction() {
        let content = "# Hello\n\nWorld"
        let tmpFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("mdv_ctx_\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tmpFile, contents: Data(content.utf8))
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
