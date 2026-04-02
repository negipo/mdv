import AppKit

class SettingsWindowController: NSWindowController {
    static let appearanceKey = "appearance"
    static let appearanceChangedNotification = Notification.Name("AppearanceSettingChanged")

    private let segmentedControl = NSSegmentedControl()

    var selectedAppearance: String {
        get {
            UserDefaults.standard.string(forKey: Self.appearanceKey) ?? "system"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.appearanceKey)
            syncSegmentedControl()
            NotificationCenter.default.post(name: Self.appearanceChangedNotification, object: nil)
        }
    }

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 120),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        setupUI()
        syncSegmentedControl()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let label = NSTextField(labelWithString: "APPEARANCE")
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabelColor

        segmentedControl.segmentCount = 3
        segmentedControl.setLabel("System", forSegment: 0)
        segmentedControl.setLabel("Light", forSegment: 1)
        segmentedControl.setLabel("Dark", forSegment: 2)
        segmentedControl.segmentStyle = .rounded
        segmentedControl.target = self
        segmentedControl.action = #selector(segmentChanged(_:))

        let stackView = NSStackView(views: [label, segmentedControl])
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 12

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func syncSegmentedControl() {
        switch selectedAppearance {
        case "light":
            segmentedControl.selectedSegment = 1
        case "dark":
            segmentedControl.selectedSegment = 2
        default:
            segmentedControl.selectedSegment = 0
        }
    }

    @objc private func segmentChanged(_ sender: NSSegmentedControl) {
        let values = ["system", "light", "dark"]
        let value = values[sender.selectedSegment]
        UserDefaults.standard.set(value, forKey: Self.appearanceKey)
        NotificationCenter.default.post(name: Self.appearanceChangedNotification, object: nil)
    }
}
