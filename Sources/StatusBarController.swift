import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem!
    private var settingsWindowController: SettingsWindowController?
    private var setupWindowController: SetupWindowController?
    
    init() {
        setupStatusItem()
        checkFirstLaunch()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "AppLock")
        }
        
        let menu = NSMenu()
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit AppLock", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    private func checkFirstLaunch() {
        if !KeychainManager.shared.hasMasterPassword() {
            showSetupWindow()
        }
    }
    
    private func showSetupWindow() {
        if setupWindowController == nil {
            setupWindowController = SetupWindowController()
        }
        setupWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

final class SetupWindowController: NSWindowController {
    private var passwordField: NSSecureTextField!
    private var confirmField: NSSecureTextField!
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "AppLock Setup"
        window.center()
        window.isReleasedWhenClosed = false
        
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = NSTextField(labelWithString: "Set Master Password")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        
        let instructionLabel = NSTextField(labelWithString: "This password will be used to unlock protected apps.")
        instructionLabel.font = NSFont.systemFont(ofSize: 12)
        instructionLabel.textColor = .secondaryLabelColor
        
        passwordField = NSSecureTextField()
        passwordField.placeholderString = "Enter password"
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.widthAnchor.constraint(equalToConstant: 250).isActive = true
        
        confirmField = NSSecureTextField()
        confirmField.placeholderString = "Confirm password"
        confirmField.translatesAutoresizingMaskIntoConstraints = false
        confirmField.widthAnchor.constraint(equalToConstant: 250).isActive = true
        
        let setButton = NSButton(title: "Set Password", target: self, action: #selector(setPassword))
        setButton.bezelStyle = .rounded
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(instructionLabel)
        stack.addArrangedSubview(passwordField)
        stack.addArrangedSubview(confirmField)
        stack.addArrangedSubview(setButton)
        
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    @objc private func setPassword() {
        let password = passwordField.stringValue
        let confirm = confirmField.stringValue
        
        if password.isEmpty {
            showAlert("Password cannot be empty.")
            return
        }
        
        if password != confirm {
            showAlert("Passwords do not match.")
            return
        }
        
        if KeychainManager.shared.setMasterPassword(password) {
            window?.close()
            
            AppMonitor.shared.updateObservedApps(AllowedAppsManager.shared.lockedApps)
        } else {
            showAlert("Failed to save password. Please try again.")
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.runModal()
    }
}