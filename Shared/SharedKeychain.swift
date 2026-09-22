//
//  SharedKeychain.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 9/22/26.
//

import Foundation
import Security

// Keychain items the app writes for LNK AutoFill, in the shared access group. Only this device,
// only while unlocked. Values are stored exactly as the app already has them (obfuscated).
enum SharedKeychain {

    enum Key: String {
        // EncryptionPassword output, the same string saved in CloudKit. Never Firestore.
        case masterPassword = "master_password"
    }

    private static let service = "com.jdev.Lock-n-Key-Wallet.autofill"

    private static func query(for key: Key) -> [String: Any] {
        [kSecClass as String:            kSecClassGenericPassword,
         kSecAttrService as String:      service,
         kSecAttrAccount as String:      key.rawValue,
         kSecAttrAccessGroup as String:  AppGroup.keychainAccessGroup]
    }

    static func set(_ value: String, for key: Key) {
        let data   = Data(value.utf8)
        let status = SecItemUpdate(query(for: key) as CFDictionary,
                                   [kSecValueData as String: data] as CFDictionary)
        guard status == errSecItemNotFound else {
            if status != errSecSuccess { print("Shared keychain update failed: \(status)") }
            return
        }
        var item = query(for: key)
        item[kSecValueData as String]      = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        if addStatus != errSecSuccess { print("Shared keychain add failed: \(addStatus)") }
    }

    static func string(for key: Key) -> String? {
        var request = query(for: key)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func removeAll() {
        let everything: [String: Any] = [kSecClass as String:           kSecClassGenericPassword,
                                         kSecAttrService as String:     service,
                                         kSecAttrAccessGroup as String: AppGroup.keychainAccessGroup]
        SecItemDelete(everything as CFDictionary)
    }
}
