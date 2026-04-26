import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        statusBarController = StatusBarController()
        
        AppMonitor.shared.updateObservedApps(AllowedAppsManager.shared.lockedApps)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(lockedAppsChanged),
            name: .lockedAppsDidChange,
            object: nil
        )
    }
    
    @objc private func lockedAppsChanged() {
        AppMonitor.shared.updateObservedApps(AllowedAppsManager.shared.lockedApps)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}