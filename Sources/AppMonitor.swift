import AppKit

final class AppMonitor {
    static let shared = AppMonitor()
    
    private var observedBundleIds: Set<String> = []
    private let queue = DispatchQueue(label: "com.applock.monitor")
    
    private init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter
        
        notificationCenter.addObserver(
            self,
            selector: #selector(didLaunchApplication(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(didTerminateApplication(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func didLaunchApplication(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            guard self.observedBundleIds.contains(bundleId) else { return }
            guard ProtectionTimer.shared.isAppAllowed(bundleId) == false else { return }
            
            DispatchQueue.main.async {
                self.terminateAndPrompt(for: app, bundleId: bundleId)
            }
        }
    }
    
    @objc private func didTerminateApplication(_ notification: Notification) {
    }
    
    private func terminateAndPrompt(for app: NSRunningApplication, bundleId: String) {
        app.terminate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PasswordDialog.shared.show { [weak self] success in
                if success {
                    let duration = TimeInterval(AllowedAppsManager.shared.protectionPeriodMinutes * 60)
                    ProtectionTimer.shared.setProtection(for: [bundleId], duration: duration)
                    
                    self?.launchApp(bundleId: bundleId)
                }
            }
        }
    }
    
    private func launchApp(bundleId: String) {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        }
    }
    
    func updateObservedApps(_ bundleIds: Set<String>) {
        queue.async { [weak self] in
            self?.observedBundleIds = bundleIds
        }
    }
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}