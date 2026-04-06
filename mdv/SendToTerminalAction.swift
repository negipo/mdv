import Foundation

enum SendToTerminalAction: String, CaseIterable {
    case relativePath
    case relativePathWithLines
    case pathLineContent
    case absolutePath
    case fileAsMarkdown

    static let defaultsKey = "sendToTerminalAction"

    static var current: SendToTerminalAction {
        get {
            guard let raw = UserDefaults.standard.string(forKey: defaultsKey),
                  let value = SendToTerminalAction(rawValue: raw) else {
                return .pathLineContent
            }
            return value
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }

    var label: String {
        switch self {
        case .relativePath: return "Copy Relative Path"
        case .relativePathWithLines: return "Copy Relative Path with Lines"
        case .pathLineContent: return "Copy Path:Line + Content"
        case .absolutePath: return "Copy Absolute Path"
        case .fileAsMarkdown: return "Copy File as Markdown"
        }
    }
}
