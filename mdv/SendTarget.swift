import Foundation

enum SendTarget {
    private static let bundleIDKey = "sendTargetBundleID"
    private static let appNameKey = "sendTargetAppName"

    static var bundleID: String? {
        get { UserDefaults.standard.string(forKey: bundleIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: bundleIDKey) }
    }

    static var appName: String? {
        get { UserDefaults.standard.string(forKey: appNameKey) }
        set { UserDefaults.standard.set(newValue, forKey: appNameKey) }
    }

    static var isConfigured: Bool {
        bundleID != nil
    }

    static var menuTitle: String {
        if let name = appName {
            return "Send to \(name)"
        }
        return "Send to\u{2026}"
    }

    static func clear() {
        bundleID = nil
        appName = nil
    }
}
