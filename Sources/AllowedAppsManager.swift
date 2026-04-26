import Foundation

final class AllowedAppsManager {
    static let shared = AllowedAppsManager()
    private let userDefaultsKey = "LockedApps"
    private let protectionPeriodKey = "ProtectionPeriodMinutes"
    
    private init() {}
    
    var lockedApps: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: userDefaultsKey)
            NotificationCenter.default.post(name: .lockedAppsDidChange, object: nil)
        }
    }
    
    var protectionPeriodMinutes: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: protectionPeriodKey)
            return value > 0 ? value : 5
        }
        set {
            UserDefaults.standard.set(newValue, forKey: protectionPeriodKey)
        }
    }
    
    func addApp(_ bundleId: String) {
        var apps = lockedApps
        apps.insert(bundleId)
        lockedApps = apps
    }
    
    func removeApp(_ bundleId: String) {
        var apps = lockedApps
        apps.remove(bundleId)
        lockedApps = apps
    }
    
    func isAppLocked(_ bundleId: String) -> Bool {
        return lockedApps.contains(bundleId)
    }
}

extension Notification.Name {
    static let lockedAppsDidChange = Notification.Name("lockedAppsDidChange")
}