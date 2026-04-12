import XCTest
@testable import mdv

final class SendToAppActionTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: SendToAppAction.defaultsKey)
        super.tearDown()
    }

    func testDefaultValueIsPathLineContent() {
        UserDefaults.standard.removeObject(forKey: SendToAppAction.defaultsKey)
        XCTAssertEqual(SendToAppAction.current, .pathLineContent)
    }

    func testSaveAndLoad() {
        SendToAppAction.current = .absolutePath
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: SendToAppAction.defaultsKey),
            "absolutePath"
        )
        XCTAssertEqual(SendToAppAction.current, .absolutePath)
    }

    func testAllCasesCount() {
        XCTAssertEqual(SendToAppAction.allCases.count, 5)
    }

    func testDisplayLabels() {
        XCTAssertEqual(SendToAppAction.relativePath.label, "Copy Relative Path")
        XCTAssertEqual(SendToAppAction.relativePathWithLines.label, "Copy Relative Path with Lines")
        XCTAssertEqual(SendToAppAction.pathLineContent.label, "Copy Path:Line + Content")
        XCTAssertEqual(SendToAppAction.absolutePath.label, "Copy Absolute Path")
        XCTAssertEqual(SendToAppAction.fileAsMarkdown.label, "Copy File as Markdown")
    }
}
