import AppKit
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.applock.app"
    private let masterPasswordKey = "masterPassword"

    private init() {}

    func setMasterPassword(_ password: String) -> Bool {
        guard let data = password.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: masterPasswordKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func getMasterPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: masterPasswordKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }

        return password
    }

    func hasMasterPassword() -> Bool {
        return getMasterPassword() != nil
    }

    func verifyMasterPassword(_ password: String) -> Bool {
        guard let stored = getMasterPassword() else { return false }
        return stored == password
    }
}