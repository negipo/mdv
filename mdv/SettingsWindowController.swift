import AppKit
import UniformTypeIdentifiers

class SettingsWindowController: NSWindowController {
    static let appearanceKey = "appearance"
    static let appearanceChangedNotification = Notification.Name("AppearanceSettingChanged")

    private var optionButtons: [NSButton] = []
    private var appNameLabel: NSTextField!
    private var clearButton: NSButton!
    private var actionPopUp: NSPopUpButton!
    private let values = ["system", "light", "dark"]

    var selectedAppearance: String {
        get {
            UserDefaults.standard.string(forKey: Self.appearanceKey) ?? "system"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.appearanceKey)
            syncSelection()
            NotificationCenter.default.post(name: Self.appearanceChangedNotification, object: nil)
        }
    }

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        setupUI()
        syncSelection()
        syncSendToSection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let appearanceSection = makeAppearanceSection()
        let sendToSection = makeSendToSection()

        let separator = NSBox()
        separator.boxType = .separator

        let stackView = NSStackView(views: [appearanceSection, separator, sendToSection])
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 16

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            separator.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -40)
        ])
    }

    private func makeAppearanceSection() -> NSView {
        let label = NSTextField(labelWithString: "APPEARANCE")
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabelColor

        let systemOption = makeOption(
            value: "system",
            label: "System",
            drawThumbnail: { rect in
                let path = NSBezierPath(rect: rect)
                NSColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1).setFill()
                path.fill()
                let triangle = NSBezierPath()
                triangle.move(to: NSPoint(x: rect.maxX, y: rect.maxY))
                triangle.line(to: NSPoint(x: rect.minX, y: rect.minY))
                triangle.line(to: NSPoint(x: rect.maxX, y: rect.minY))
                triangle.close()
                NSColor(red: 0.16, green: 0.17, blue: 0.21, alpha: 1).setFill()
                triangle.fill()
            }
        )

        let lightOption = makeOption(
            value: "light",
            label: "Light",
            drawThumbnail: { rect in
                NSColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 0, yRadius: 0).fill()
            }
        )

        let darkOption = makeOption(
            value: "dark",
            label: "Dark",
            drawThumbnail: { rect in
                NSColor(red: 0.16, green: 0.17, blue: 0.21, alpha: 1).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 0, yRadius: 0).fill()
            }
        )

        let optionsStack = NSStackView(views: [systemOption, lightOption, darkOption])
        optionsStack.orientation = .horizontal
        optionsStack.spacing = 16
        optionsStack.alignment = .top

        let section = NSStackView(views: [label, optionsStack])
        section.orientation = .vertical
        section.alignment = .centerX
        section.spacing = 12
        return section
    }

    private func makeSendToSection() -> NSView {
        let label = NSTextField(labelWithString: "SEND TO")
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabelColor

        appNameLabel = NSTextField(labelWithString: "")
        appNameLabel.font = .systemFont(ofSize: 12, weight: .medium)
        appNameLabel.lineBreakMode = .byTruncatingTail
        appNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let chooseButton = NSButton(title: "Choose\u{2026}", target: self, action: #selector(chooseAppClicked(_:)))
        chooseButton.bezelStyle = .rounded
        chooseButton.controlSize = .small
        chooseButton.font = .systemFont(ofSize: 11)

        clearButton = NSButton(title: "Clear", target: self, action: #selector(clearAppClicked(_:)))
        clearButton.bezelStyle = .rounded
        clearButton.controlSize = .small
        clearButton.font = .systemFont(ofSize: 11)

        actionPopUp = NSPopUpButton(frame: .zero, pullsDown: false)
        actionPopUp.controlSize = .small
        actionPopUp.font = .systemFont(ofSize: 11)
        for action in SendToAppAction.allCases {
            actionPopUp.addItem(withTitle: action.label)
        }
        actionPopUp.target = self
        actionPopUp.action = #selector(actionOptionChanged(_:))

        let row = NSStackView(views: [appNameLabel, chooseButton, clearButton, actionPopUp])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY

        let section = NSStackView(views: [label, row])
        section.orientation = .vertical
        section.alignment = .centerX
        section.spacing = 12

        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.widthAnchor.constraint(lessThanOrEqualToConstant: 400)
        ])

        return section
    }

    @objc private func chooseAppClicked(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return }

        let appName = FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")

        SendTarget.bundleID = bundleID
        SendTarget.appName = appName
        syncSendToSection()
    }

    @objc private func clearAppClicked(_ sender: Any?) {
        SendTarget.clear()
        syncSendToSection()
    }

    @objc private func actionOptionChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        guard index >= 0, index < SendToAppAction.allCases.count else { return }
        SendToAppAction.current = SendToAppAction.allCases[index]
    }

    private func syncSendToSection() {
        if SendTarget.isConfigured {
            appNameLabel.stringValue = SendTarget.appName ?? "Unknown"
            appNameLabel.textColor = .labelColor
            clearButton.isHidden = false
            actionPopUp.isEnabled = true
        } else {
            appNameLabel.stringValue = "No app selected"
            appNameLabel.textColor = .secondaryLabelColor
            clearButton.isHidden = true
            actionPopUp.isEnabled = false
        }

        let currentIndex = SendToAppAction.allCases.firstIndex(of: SendToAppAction.current) ?? 2
        actionPopUp.selectItem(at: currentIndex)
    }

    private func makeOption(value: String, label: String, drawThumbnail: @escaping (NSRect) -> Void) -> NSView {
        let thumbnailSize = NSSize(width: 56, height: 40)

        let thumbnail = ThumbnailView(frame: NSRect(origin: .zero, size: thumbnailSize), draw: drawThumbnail)
        thumbnail.wantsLayer = true
        thumbnail.layer?.cornerRadius = 6
        thumbnail.layer?.masksToBounds = true
        thumbnail.layer?.borderWidth = 1
        thumbnail.layer?.borderColor = NSColor.separatorColor.cgColor

        let button = NSButton(frame: .zero)
        button.title = ""
        button.bezelStyle = .toolbar
        button.isBordered = false
        button.setButtonType(.onOff)
        button.target = self
        button.action = #selector(optionClicked(_:))
        button.tag = values.firstIndex(of: value) ?? 0
        optionButtons.append(button)

        let buttonContainer = NSView(frame: NSRect(origin: .zero, size: thumbnailSize))
        buttonContainer.addSubview(thumbnail)
        buttonContainer.addSubview(button)
        thumbnail.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonContainer.widthAnchor.constraint(equalToConstant: thumbnailSize.width),
            buttonContainer.heightAnchor.constraint(equalToConstant: thumbnailSize.height),
            thumbnail.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            thumbnail.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            thumbnail.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            thumbnail.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            button.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            button.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor)
        ])

        let textLabel = NSTextField(labelWithString: label)
        textLabel.font = .systemFont(ofSize: 11)
        textLabel.alignment = .center
        textLabel.textColor = .labelColor

        let stack = NSStackView(views: [buttonContainer, textLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 4

        return stack
    }

    private func syncSelection() {
        let currentIndex = values.firstIndex(of: selectedAppearance) ?? 0
        for (index, button) in optionButtons.enumerated() {
            button.state = index == currentIndex ? .on : .off
            if let container = button.superview {
                container.subviews.compactMap { $0 as? ThumbnailView }.first?.isSelected = index == currentIndex
            }
        }
    }

    @objc private func optionClicked(_ sender: NSButton) {
        let value = values[sender.tag]
        UserDefaults.standard.set(value, forKey: Self.appearanceKey)
        syncSelection()
        NotificationCenter.default.post(name: Self.appearanceChangedNotification, object: nil)
    }
}

private class ThumbnailView: NSView {
    var isSelected = false {
        didSet {
            layer?.borderColor = isSelected
                ? NSColor.controlAccentColor.cgColor
                : NSColor.separatorColor.cgColor
            layer?.borderWidth = isSelected ? 2 : 1
        }
    }

    private let drawBlock: (NSRect) -> Void

    init(frame: NSRect, draw: @escaping (NSRect) -> Void) {
        self.drawBlock = draw
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        drawBlock(bounds)
    }
}
