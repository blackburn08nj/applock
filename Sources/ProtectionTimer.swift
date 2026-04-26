import Foundation

final class ProtectionTimer {
    static let shared = ProtectionTimer()
    
    private var allowedApps: Set<String> = []
    private var expirationTime: Date?
    private let queue = DispatchQueue(label: "com.applock.protection")
    
    private init() {}
    
    func setProtection(for bundleIds: Set<String>, duration: TimeInterval) {
        queue.sync {
            allowedApps = bundleIds
            expirationTime = Date().addingTimeInterval(duration)
        }
    }
    
    func isAppAllowed(_ bundleId: String) -> Bool {
        return queue.sync {
            guard let expiration = expirationTime else { return false }
            if Date() > expiration {
                allowedApps.removeAll()
                expirationTime = nil
                return false
            }
            return allowedApps.contains(bundleId)
        }
    }
    
    func clearAll() {
        queue.sync {
            allowedApps.removeAll()
            expirationTime = nil
        }
    }
}