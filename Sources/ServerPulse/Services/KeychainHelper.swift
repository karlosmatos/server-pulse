import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.serverpulse.n8nAPIKey"

    static func set(_ value: String, account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let deleteStatus = SecItemDelete(query as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            assertionFailure("Keychain delete failed: \(deleteStatus)")
            return
        }
        guard !value.isEmpty else { return }
        var attributes = query
        attributes[kSecValueData] = Data(value.utf8)
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        assert(addStatus == errSecSuccess, "Keychain add failed: \(addStatus)")
    }

    static func get(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
