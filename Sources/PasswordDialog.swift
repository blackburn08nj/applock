import AppKit

final class PasswordDialog {
    static let shared = PasswordDialog()
    
    private var onCompletion: ((Bool) -> Void)?
    private var alert: NSAlert?
    private var passwordField: NSSecureTextField?
    
    private init() {}
    
    func show(completion: @escaping (Bool) -> Void) {
        onCompletion = completion
        
        let alert = NSAlert()
        alert.messageText = "App Locked"
        alert.informativeText = "Enter your master password to unlock."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Unlock")
        alert.addButton(withTitle: "Cancel")
        
        let passwordField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        passwordField.placeholderString = "Password"
        alert.accessoryView = passwordField
        
        self.alert = alert
        self.passwordField = passwordField
        
        alert.beginSheetModal(for: NSApp.keyWindow ?? NSApp.windows.first!) { [weak self] response in
            guard let self = self else { return }
            
            if response == .alertFirstButtonReturn {
                let password = self.passwordField?.stringValue ?? ""
                if KeychainManager.shared.verifyMasterPassword(password) {
                    self.onCompletion?(true)
                } else {
                    self.showFailedAttempt()
                }
            } else {
                self.onCompletion?(false)
            }
        }
    }
    
    private func showFailedAttempt() {
        let alert = NSAlert()
        alert.messageText = "Incorrect Password"
        alert.informativeText = "The password you entered is incorrect. Please try again."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Try Again")
        alert.addButton(withTitle: "Cancel")
        
        if let window = self.alert?.window {
            alert.beginSheetModal(for: window) { [weak self] response in
                if response == .alertFirstButtonReturn {
                    self?.show(completion: self?.onCompletion ?? { _ in })
                } else {
                    self?.onCompletion?(false)
                }
            }
        }
    }
}