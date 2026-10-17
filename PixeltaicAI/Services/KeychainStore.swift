
import Foundation
import Security

/// Tiny Keychain wrapper for the usage counters. Unlike UserDefaults, Keychain items survive
/// deleting and reinstalling the app, so a reinstall does not hand out a fresh free allowance.
/// Everything fails soft: when the Keychain is unavailable the callers simply fall back to UserDefaults.
enum KeychainStore {

    private static var service: String {
        (Bundle.main.bundleIdentifier ?? "clarity") + ".usage"
    }

    private static func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    static func read(_ account: String) -> Data? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }

    @discardableResult
    static func write(_ data: Data, account: String) -> Bool {
        let query = baseQuery(account)
        let update: [String: Any] = [kSecValueData as String: data]

        let updated = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updated == errSecSuccess { return true }
        guard updated == errSecItemNotFound else { return false }

        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }
}
