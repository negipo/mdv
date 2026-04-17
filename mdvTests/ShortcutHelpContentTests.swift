import XCTest
@testable import mdv

final class ShortcutHelpContentTests: XCTestCase {
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

    // ヘルプ本文のタイトルがKeyboard Shortcuts & Mouse Manipulationsになっている
    func testTitleIncludesMouseManipulations() {
        let content = controller.generateShortcutHelpContent()
        XCTAssertTrue(
            content.contains("# Keyboard Shortcuts & Mouse Manipulations"),
            "Title should be 'Keyboard Shortcuts & Mouse Manipulations'"
        )
    }

    // Mouse Manipulationsセクションが含まれている
    func testMouseManipulationsSectionExists() {
        let content = controller.generateShortcutHelpContent()
        XCTAssertTrue(
            content.contains("## Mouse Manipulations"),
            "Mouse Manipulations section should exist"
        )
    }

    // Mermaid Overlayのホイール拡大縮小が記載されている
    func testMermaidWheelZoomDocumented() {
        let content = controller.generateShortcutHelpContent()
        XCTAssertTrue(
            content.contains("Mermaid"),
            "Mermaid should be mentioned"
        )
        XCTAssertTrue(
            content.contains("Scroll") || content.contains("scroll"),
            "Scroll (wheel) action should be documented"
        )
    }

    // Mermaid Overlayのドラッグ移動が記載されている
    func testMermaidDragPanDocumented() {
        let content = controller.generateShortcutHelpContent()
        XCTAssertTrue(
            content.contains("Drag") || content.contains("drag"),
            "Drag action should be documented"
        )
    }

    // Escで閉じられることが記載されている
    func testMermaidEscCloseDocumented() {
        let content = controller.generateShortcutHelpContent()
        XCTAssertTrue(
            content.contains("Esc") || content.contains("Escape"),
            "Esc key should be documented"
        )
    }

    // 既存のSingle-Key Shortcutsセクションは維持されている
    func testSingleKeyShortcutsSectionStillExists() {
        let content = controller.generateShortcutHelpContent()
        XCTAssertTrue(
            content.contains("## Single-Key Shortcuts"),
            "Single-Key Shortcuts section should be preserved"
        )
    }
}
