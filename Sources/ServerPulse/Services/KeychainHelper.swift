import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.serverpulse.n8nAPIKey"

    @discardableResult
    static func set(_ value: String, account: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        guard delete(account: account) else {
            return false
        }
        guard !value.isEmpty else { return true }
        var attributes = query
        attributes[kSecValueData] = Data(value.utf8)
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            print("Keychain add failed (\(addStatus)): \(message(for: addStatus))")
            return false
        }
        return true
    }

    @discardableResult
    static func delete(account: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("Keychain delete failed (\(status)): \(message(for: status))")
            return false
        }
        return true
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

    private static func message(for status: OSStatus) -> String {
        (SecCopyErrorMessageString(status, nil) as String?) ?? "Unknown OSStatus"
    }
}
