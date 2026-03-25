import AppKit

class TitlebarTabsWindow: NSWindow {
    static let tabBarIdentifier = NSUserInterfaceItemIdentifier("_mdvTabBar")

    private var windowButtonsBackdrop: WindowButtonsBackdropView?
    private var windowDragHandle: WindowDragView?
    private var tocToggleButton: NSButton?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        tabbingMode = .preferred
        tabbingIdentifier = "mdv-markdown"
        titleVisibility = .hidden

        let toolbar = TitlebarTabsToolbar(identifier: "mdv-toolbar")
        self.toolbar = toolbar
        toolbarStyle = .unifiedCompact
    }

    override var title: String {
        didSet {
            if let toolbar = toolbar as? TitlebarTabsToolbar {
                toolbar.titleText = title
            }
        }
    }

    override func becomeMain() {
        super.becomeMain()
        if let tabGroup, !tabGroup.isTabBarVisible {
            toggleTabBar(nil)
        }
    }

    override func update() {
        super.update()
        hideToolbarOverflowButton()
        hideTitleBarSeparators()
    }

    override func updateConstraintsIfNeeded() {
        super.updateConstraintsIfNeeded()
        hideToolbarOverflowButton()
        hideTitleBarSeparators()
    }

    override func addTitlebarAccessoryViewController(_ childViewController: NSTitlebarAccessoryViewController) {
        let isTab = isTabBar(childViewController)

        if isTab {
            childViewController.layoutAttribute = .right
            titleVisibility = .hidden
            childViewController.identifier = Self.tabBarIdentifier
            if let toolbar = toolbar as? TitlebarTabsToolbar {
                toolbar.titleIsHidden = true
            }
        }

        super.addTitlebarAccessoryViewController(childViewController)

        if isTab {
            pushTabsToTitlebar(childViewController)
        }
    }

    override func removeTitlebarAccessoryViewController(at index: Int) {
        let isTab = titlebarAccessoryViewControllers[index].identifier == Self.tabBarIdentifier
        if isTab {
            return
        }
        super.removeTitlebarAccessoryViewController(at: index)
    }

    private func isTabBar(_ childViewController: NSTitlebarAccessoryViewController) -> Bool {
        if childViewController.identifier == nil {
            if childViewController.view.containsView(withClassName: "NSTabBar") {
                return true
            }
            if childViewController.layoutAttribute == .bottom &&
                childViewController.view.className == "NSView" &&
                childViewController.view.subviews.isEmpty {
                return true
            }
            return false
        }
        return childViewController.identifier == Self.tabBarIdentifier
    }

    private func pushTabsToTitlebar(_ tabBarController: NSTitlebarAccessoryViewController) {
        DispatchQueue.main.async { [weak self] in
            let accessoryView = tabBarController.view
            guard let accessoryClipView = accessoryView.superview else { return }
            guard let titlebarView = accessoryClipView.superview else { return }
            guard titlebarView.className == "NSTitlebarView" else { return }
            guard let toolbarView = titlebarView.subviews.first(where: {
                $0.className == "NSToolbarView"
            }) else { return }

            self?.addWindowButtonsBackdrop(titlebarView: titlebarView, toolbarView: toolbarView)
            guard let windowButtonsBackdrop = self?.windowButtonsBackdrop else { return }

            self?.addTocToggleButton(titlebarView: titlebarView, toolbarView: toolbarView)

            self?.addWindowDragHandle(titlebarView: titlebarView, toolbarView: toolbarView)

            let tabLeftAnchor: NSLayoutXAxisAnchor
            if let tocButton = self?.tocToggleButton, tocButton.superview == titlebarView {
                tabLeftAnchor = tocButton.rightAnchor
            } else {
                tabLeftAnchor = windowButtonsBackdrop.rightAnchor
            }

            accessoryClipView.translatesAutoresizingMaskIntoConstraints = false
            accessoryClipView.leftAnchor.constraint(equalTo: tabLeftAnchor).isActive = true
            accessoryClipView.rightAnchor.constraint(equalTo: toolbarView.rightAnchor).isActive = true
            accessoryClipView.topAnchor.constraint(equalTo: toolbarView.topAnchor).isActive = true
            accessoryClipView.heightAnchor.constraint(equalTo: toolbarView.heightAnchor).isActive = true

            accessoryView.translatesAutoresizingMaskIntoConstraints = false
            accessoryView.leftAnchor.constraint(equalTo: accessoryClipView.leftAnchor).isActive = true
            accessoryView.rightAnchor.constraint(equalTo: accessoryClipView.rightAnchor).isActive = true
            accessoryView.topAnchor.constraint(equalTo: accessoryClipView.topAnchor).isActive = true
            accessoryView.heightAnchor.constraint(equalTo: accessoryClipView.heightAnchor).isActive = true

            if let tabBar = accessoryView.firstDescendant(withClassName: "NSTabBar") {
                let expectedHeight = accessoryClipView.frame.height - 12
                if tabBar.frame.height > expectedHeight {
                    var tabFrame = tabBar.frame
                    tabFrame.size.height = expectedHeight
                    tabBar.frame = tabFrame
                }
            }

            accessoryClipView.wantsLayer = true
            accessoryClipView.layer?.sublayerTransform = CATransform3DMakeTranslation(0, -2, 0)

            self?.hideToolbarOverflowButton()
            self?.hideTitleBarSeparators()
        }
    }

    private func addWindowButtonsBackdrop(titlebarView: NSView, toolbarView: NSView) {
        guard windowButtonsBackdrop?.superview != titlebarView else { return }
        windowButtonsBackdrop?.removeFromSuperview()
        windowButtonsBackdrop = nil

        let hasButtons = !(standardWindowButton(.closeButton)?.isHiddenOrHasHiddenAncestor ?? true)

        let view = WindowButtonsBackdropView()
        view.identifier = NSUserInterfaceItemIdentifier("_windowButtonsBackdrop")
        titlebarView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.leftAnchor.constraint(equalTo: toolbarView.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: toolbarView.leftAnchor, constant: hasButtons ? 78 : 0).isActive = true
        view.topAnchor.constraint(equalTo: toolbarView.topAnchor).isActive = true
        view.heightAnchor.constraint(equalTo: toolbarView.heightAnchor).isActive = true

        windowButtonsBackdrop = view
    }

    private func addTocToggleButton(titlebarView: NSView, toolbarView: NSView) {
        guard tocToggleButton?.superview != titlebarView else { return }
        tocToggleButton?.removeFromSuperview()
        tocToggleButton = nil

        guard let windowButtonsBackdrop else { return }

        let button = NSButton(frame: .zero)
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Table of Contents")?.withSymbolConfiguration(config)
        button.contentTintColor = .labelColor
        button.bezelStyle = .toolbar
        button.setButtonType(.momentaryPushIn)
        button.isBordered = false
        button.target = nil
        button.action = #selector(MarkdownWindowController.toggleToc(_:))
        button.identifier = NSUserInterfaceItemIdentifier("_tocToggleButton")
        titlebarView.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.leftAnchor.constraint(equalTo: windowButtonsBackdrop.rightAnchor, constant: 4).isActive = true
        button.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor).isActive = true
        button.widthAnchor.constraint(equalToConstant: 36).isActive = true
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true

        tocToggleButton = button
    }

    private func addWindowDragHandle(titlebarView: NSView, toolbarView: NSView) {
        guard windowDragHandle?.superview != titlebarView.superview else { return }
        windowDragHandle?.removeFromSuperview()

        let view = WindowDragView()
        view.identifier = NSUserInterfaceItemIdentifier("_windowDragHandle")
        titlebarView.superview?.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leftAnchor.constraint(equalTo: toolbarView.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: toolbarView.rightAnchor).isActive = true
        view.topAnchor.constraint(equalTo: toolbarView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: toolbarView.topAnchor, constant: 12).isActive = true

        windowDragHandle = view
    }

    private var titlebarContainer: NSView? {
        contentView?.firstViewFromRoot(withClassName: "NSTitlebarContainerView")
    }

    private func hideTitleBarSeparators() {
        guard let titlebarContainer else { return }
        for v in titlebarContainer.descendantsViews(withClassName: "NSTitlebarSeparatorView") {
            v.isHidden = true
        }
    }

    private func hideToolbarOverflowButton() {
        guard let windowButtonsBackdrop else { return }
        guard let titlebarView = windowButtonsBackdrop.superview else { return }
        guard titlebarView.className == "NSTitlebarView" else { return }
        guard let toolbarView = titlebarView.subviews.first(where: {
            $0.className == "NSToolbarView"
        }) else { return }
        toolbarView.subviews.first(where: { $0.className == "NSToolbarClippedItemsIndicatorViewer" })?.isHidden = true
    }
}

// MARK: - WindowDragView

private class WindowDragView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let pointInSelf = convert(point, from: superview)
        guard bounds.contains(pointInSelf) else { return nil }

        guard let titlebarView = superview?.firstDescendant(withClassName: "NSTitlebarView"),
              let tabBar = titlebarView.firstDescendant(withClassName: "NSTabBar") else {
            return super.hitTest(point)
        }

        if let tocButton = titlebarView.subviews.first(where: { $0.identifier?.rawValue == "_tocToggleButton" }) {
            let pointInButton = tocButton.convert(point, from: superview)
            if tocButton.bounds.contains(pointInButton) {
                return nil
            }
        }

        let pointInTabBar = tabBar.convert(point, from: superview)
        if tabBar.bounds.contains(pointInTabBar) {
            return nil
        }

        return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        if event.type == .leftMouseDown && event.clickCount == 1 {
            window?.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
}

// MARK: - WindowButtonsBackdropView

private class WindowButtonsBackdropView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - TitlebarTabsToolbar

private class TitlebarTabsToolbar: NSToolbar, NSToolbarDelegate {
    private let titleTextField: NSTextField = {
        let field = NSTextField(labelWithString: "")
        field.alignment = .center
        field.lineBreakMode = .byTruncatingTail
        field.textColor = .secondaryLabelColor
        field.font = .titleBarFont(ofSize: NSFont.systemFontSize)
        return field
    }()

    var titleText: String {
        get { titleTextField.stringValue }
        set { titleTextField.stringValue = newValue }
    }

    var titleIsHidden: Bool {
        get { titleTextField.isHidden }
        set { titleTextField.isHidden = newValue }
    }

    override init(identifier: NSToolbar.Identifier) {
        super.init(identifier: identifier)
        delegate = self
        showsBaselineSeparator = false
        centeredItemIdentifiers.insert(.init("TitleText"))
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier.rawValue == "TitleText" {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = titleTextField
            item.visibilityPriority = .user
            titleTextField.translatesAutoresizingMaskIntoConstraints = false
            titleTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
            titleTextField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            return item
        }

        return NSToolbarItem(itemIdentifier: itemIdentifier)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("TitleText")]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .init("TitleText"), .flexibleSpace]
    }
}

// MARK: - NSView Extension

extension NSView {
    var rootView: NSView {
        var current = self
        while let parent = current.superview {
            current = parent
        }
        return current
    }

    func containsView(withClassName name: String) -> Bool {
        if String(describing: type(of: self)) == name { return true }
        for subview in subviews where subview.containsView(withClassName: name) {
            return true
        }
        return false
    }

    func firstDescendant(withClassName name: String) -> NSView? {
        for subview in subviews {
            if String(describing: type(of: subview)) == name {
                return subview
            } else if let found = subview.firstDescendant(withClassName: name) {
                return found
            }
        }
        return nil
    }

    func descendantsViews(withClassName name: String) -> [NSView] {
        var result = [NSView]()
        for subview in subviews {
            if String(describing: type(of: subview)) == name {
                result.append(subview)
            }
            result += subview.descendantsViews(withClassName: name)
        }
        return result
    }

    func firstViewFromRoot(withClassName name: String) -> NSView? {
        let root = rootView
        if String(describing: type(of: root)) == name { return root }
        return root.firstDescendant(withClassName: name)
    }
}
