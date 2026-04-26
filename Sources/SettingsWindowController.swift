import AppKit

final class SettingsWindowController: NSWindowController {
    private var tableView: NSTableView!
    private var bundleIdField: NSTextField!
    private var protectionPeriodField: NSTextField!
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AppLock Settings"
        window.center()
        window.minSize = NSSize(width: 400, height: 300)
        
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let lockedAppsLabel = NSTextField(labelWithString: "Locked Applications")
        lockedAppsLabel.font = NSFont.boldSystemFont(ofSize: 14)
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("BundleId"))
        column.title = "Bundle Identifier"
        column.width = 400
        tableView.addTableColumn(column)
        tableView.headerView = nil
        
        scrollView.documentView = tableView
        
        let addRemoveStack = NSStackView()
        addRemoveStack.orientation = .horizontal
        addRemoveStack.spacing = 8
        
        bundleIdField = NSTextField()
        bundleIdField.placeholderString = "com.example.app"
        bundleIdField.translatesAutoresizingMaskIntoConstraints = false
        bundleIdField.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        
        let addButton = NSButton(title: "Add", target: self, action: #selector(addApp))
        let removeButton = NSButton(title: "Remove Selected", target: self, action: #selector(removeApp))
        
        addRemoveStack.addArrangedSubview(bundleIdField)
        addRemoveStack.addArrangedSubview(addButton)
        addRemoveStack.addArrangedSubview(removeButton)
        
        let protectionStack = NSStackView()
        protectionStack.orientation = .horizontal
        protectionStack.spacing = 8
        
        let protectionLabel = NSTextField(labelWithString: "Protection Period (minutes):")
        protectionPeriodField = NSTextField()
        protectionPeriodField.stringValue = "\(AllowedAppsManager.shared.protectionPeriodMinutes)"
        protectionPeriodField.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        let savePeriodButton = NSButton(title: "Save", target: self, action: #selector(saveProtectionPeriod))
        
        protectionStack.addArrangedSubview(protectionLabel)
        protectionStack.addArrangedSubview(protectionPeriodField)
        protectionStack.addArrangedSubview(savePeriodButton)
        
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        let passwordSection = createPasswordSection()
        
        mainStack.addArrangedSubview(lockedAppsLabel)
        mainStack.addArrangedSubview(scrollView)
        mainStack.addArrangedSubview(addRemoveStack)
        mainStack.addArrangedSubview(separator)
        mainStack.addArrangedSubview(protectionStack)
        mainStack.addArrangedSubview(passwordSection)
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            scrollView.heightAnchor.constraint(equalToConstant: 150),
            scrollView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -40),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }
    
    private func createPasswordSection() -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 8
        
        let passwordLabel = NSTextField(labelWithString: "Change Master Password")
        passwordLabel.font = NSFont.boldSystemFont(ofSize: 14)
        
        let currentPasswordField = NSSecureTextField()
        currentPasswordField.placeholderString = "Current Password"
        currentPasswordField.translatesAutoresizingMaskIntoConstraints = false
        
        let newPasswordField = NSSecureTextField()
        newPasswordField.placeholderString = "New Password"
        newPasswordField.translatesAutoresizingMaskIntoConstraints = false
        
        let confirmPasswordField = NSSecureTextField()
        confirmPasswordField.placeholderString = "Confirm New Password"
        confirmPasswordField.translatesAutoresizingMaskIntoConstraints = false
        
        let changeButton = NSButton(title: "Change Password", target: self, action: #selector(changePassword))
        
        container.addArrangedSubview(passwordLabel)
        container.addArrangedSubview(currentPasswordField)
        container.addArrangedSubview(newPasswordField)
        container.addArrangedSubview(confirmPasswordField)
        container.addArrangedSubview(changeButton)
        
        currentPasswordField.tag = 100
        newPasswordField.tag = 101
        confirmPasswordField.tag = 102
        changeButton.tag = 103
        
        return container
    }
    
    @objc private func addApp() {
        let bundleId = bundleIdField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !bundleId.isEmpty else { return }
        
        AllowedAppsManager.shared.addApp(bundleId)
        AppMonitor.shared.updateObservedApps(AllowedAppsManager.shared.lockedApps)
        tableView.reloadData()
        bundleIdField.stringValue = ""
    }
    
    @objc private func removeApp() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return }
        
        let apps = Array(AllowedAppsManager.shared.lockedApps).sorted()
        let bundleId = apps[selectedRow]
        
        AllowedAppsManager.shared.removeApp(bundleId)
        AppMonitor.shared.updateObservedApps(AllowedAppsManager.shared.lockedApps)
        tableView.reloadData()
    }
    
    @objc private func saveProtectionPeriod() {
        guard let value = Int(protectionPeriodField.stringValue), value > 0 else {
            let alert = NSAlert()
            alert.messageText = "Invalid Value"
            alert.informativeText = "Please enter a positive number for the protection period."
            alert.runModal()
            return
        }
        
        AllowedAppsManager.shared.protectionPeriodMinutes = value
    }
    
    @objc private func changePassword(_ sender: NSButton) {
        guard let contentView = window?.contentView else { return }
        
        let currentField = contentView.viewWithTag(100) as? NSSecureTextField
        let newField = contentView.viewWithTag(101) as? NSSecureTextField
        let confirmField = contentView.viewWithTag(102) as? NSSecureTextField
        
        let currentPassword = currentField?.stringValue ?? ""
        let newPassword = newField?.stringValue ?? ""
        let confirmPassword = confirmField?.stringValue ?? ""
        
        if !KeychainManager.shared.verifyMasterPassword(currentPassword) {
            showAlert(title: "Error", message: "Current password is incorrect.")
            return
        }
        
        if newPassword.isEmpty {
            showAlert(title: "Error", message: "New password cannot be empty.")
            return
        }
        
        if newPassword != confirmPassword {
            showAlert(title: "Error", message: "New passwords do not match.")
            return
        }
        
        if KeychainManager.shared.setMasterPassword(newPassword) {
            showAlert(title: "Success", message: "Password changed successfully.")
            currentField?.stringValue = ""
            newField?.stringValue = ""
            confirmField?.stringValue = ""
        } else {
            showAlert(title: "Error", message: "Failed to save password.")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}

extension SettingsWindowController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return AllowedAppsManager.shared.lockedApps.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("AppCell")
        var cellView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        
        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = identifier
            
            let textField = NSTextField()
            textField.isBezeled = false
            textField.drawsBackground = false
            textField.isEditable = false
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            cellView?.addSubview(textField)
            cellView?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 5),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -5),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }
        
        let apps = Array(AllowedAppsManager.shared.lockedApps).sorted()
        cellView?.textField?.stringValue = apps[row]
        
        return cellView
    }
}