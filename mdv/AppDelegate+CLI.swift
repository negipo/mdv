import AppKit

// MARK: - CLI

extension AppDelegate {
    private static let cliInstallPath = "/usr/local/bin/mdv"
    private static let cliSearchPaths = ["/opt/homebrew/bin/mdv", "/usr/local/bin/mdv"]
    private static let cliPromptShownKey = "CLIInstallPromptShown"
    private var installedCLIPath: String? {
        Self.cliSearchPaths.first { path in
            (try? FileManager.default.attributesOfItem(atPath: path)) != nil
        }
    }
    private var isCLIInstalled: Bool { installedCLIPath != nil }

    func promptCLIInstallIfNeeded() {
        if isCLIInstalled { return }
        if UserDefaults.standard.bool(forKey: Self.cliPromptShownKey) { return }

        UserDefaults.standard.set(true, forKey: Self.cliPromptShownKey)

        let alert = NSAlert()
        alert.messageText = "Install command line tool?"
        alert.informativeText = "Would you like to use mdv from the terminal? " +
            "You can also install it later from the mdv menu."
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Not Now")

        if alert.runModal() == .alertFirstButtonReturn {
            performCLIInstall()
        }
    }

    @objc func installCLI(_ sender: Any?) {
        if isCLIInstalled {
            let alert = NSAlert()
            alert.messageText = "Command line tool is already installed."
            alert.informativeText = "The mdv command is available at \(installedCLIPath ?? Self.cliInstallPath)."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        performCLIInstall()
    }

    private func performCLIInstall() {
        guard let resourcePath = Bundle.main.resourcePath else {
            showInstallFailedAlert(message: "Could not locate app bundle resources.")
            return
        }

        let bundleCLIPath = resourcePath + "/bin/mdv"
        let cmd = "mkdir -p /usr/local/bin && ln -sf '\(bundleCLIPath)' '\(Self.cliInstallPath)'"
        runCLIInstallScript("do shell script \"\(cmd)\" with administrator privileges")
    }

    private func showInstallFailedAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Installation failed."
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func runCLIInstallScript(_ script: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]

            let pipe = Pipe()
            process.standardError = pipe

            do {
                try process.run()
            } catch {
                DispatchQueue.main.async {
                    self.showInstallFailedAlert(message: error.localizedDescription)
                }
                return
            }

            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            DispatchQueue.main.async {
                self.handleInstallResult(process: process, errorData: errorData)
            }
        }
    }

    private func handleInstallResult(process: Process, errorData: Data) {
        if process.terminationStatus == 0 {
            let alert = NSAlert()
            alert.messageText = "Command line tool installed successfully."
            alert.informativeText = "You can now use 'mdv' from the terminal."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } else {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            if errorMessage.contains("User canceled") { return }
            showInstallFailedAlert(message: errorMessage)
        }
    }
}
