import XCTest
@testable import mdv

final class SendToTerminalActionTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: SendToTerminalAction.defaultsKey)
        super.tearDown()
    }

    func testDefaultValueIsPathLineContent() {
        UserDefaults.standard.removeObject(forKey: SendToTerminalAction.defaultsKey)
        XCTAssertEqual(SendToTerminalAction.current, .pathLineContent)
    }

    func testSaveAndLoad() {
        SendToTerminalAction.current = .absolutePath
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: SendToTerminalAction.defaultsKey),
            "absolutePath"
        )
        XCTAssertEqual(SendToTerminalAction.current, .absolutePath)
    }

    func testAllCasesCount() {
        XCTAssertEqual(SendToTerminalAction.allCases.count, 5)
    }

    func testDisplayLabels() {
        XCTAssertEqual(SendToTerminalAction.relativePath.label, "Copy Relative Path")
        XCTAssertEqual(SendToTerminalAction.relativePathWithLines.label, "Copy Relative Path with Lines")
        XCTAssertEqual(SendToTerminalAction.pathLineContent.label, "Copy Path:Line + Content")
        XCTAssertEqual(SendToTerminalAction.absolutePath.label, "Copy Absolute Path")
        XCTAssertEqual(SendToTerminalAction.fileAsMarkdown.label, "Copy File as Markdown")
    }
}
