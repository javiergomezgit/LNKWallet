//
//  AutoFillSync.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 9/22/26.
//

import Foundation
import AuthenticationServices
import FirebaseAuth

// Keeps LNK AutoFill in step with the vault: the obfuscated offline copy it fills from, and the
// QuickType suggestions iOS shows above the keyboard. Call refresh() after anything that changes the
// password items, and clear() whenever the vault stops belonging to this device's user.
//
// The suggestions hold each item's domain and username in plaintext, in a system store on the
// device (never synced, never the password). Everything written to the App Group stays obfuscated.
enum AutoFillSync {

    static func refresh() {
        guard let user = Auth.auth().currentUser, let created = user.metadata.creationDate else { return }
        let uid          = user.uid
        let creationDate = Int(created.timeIntervalSince1970)

        DBManager.shared.getAllEncryptedPasswordRecords(userID: uid) { encryptedRecords in
            // Failed or offline fetch: keep the last good copy rather than wiping it
            guard let encryptedRecords = encryptedRecords else { return }

            DispatchQueue.global(qos: .utility).async {
                AutoFillCache.write(encryptedRecords, uid: uid)
                let identities = encryptedRecords.compactMap {
                    identity(for: $0, secretKey: uid, creationDate: creationDate)
                }
                replaceIdentities(with: identities)
            }
        }
    }

    static func clear() {
        AutoFillCache.clear()
        ASCredentialIdentityStore.shared.removeAllCredentialIdentities { _, error in
            if let error = error { print("Clearing AutoFill suggestions failed: \(error)") }
        }
    }

    // MARK: — Suggestions

    private static func identity(for encrypted: PasswordRecord, secretKey: String, creationDate: Int) -> ASPasswordCredentialIdentity? {
        let decrypted = encrypted.decrypted(secretKey: secretKey, creationDate: creationDate)
        guard let host = ServiceHost.normalized(decrypted.website) else { return nil }

        let user = decrypted.username.isEmpty ? decrypted.email : decrypted.username
        guard !user.isEmpty else { return nil }

        return ASPasswordCredentialIdentity(
            serviceIdentifier: ASCredentialServiceIdentifier(identifier: host, type: .domain),
            user:              user,
            recordIdentifier:  encrypted.documentID)
    }

    private static func replaceIdentities(with identities: [ASPasswordCredentialIdentity]) {
        let store = ASCredentialIdentityStore.shared
        store.getState { state in
            // Nothing to do until the user turns LNK Wallet on in Settings › AutoFill & Passwords
            guard state.isEnabled else { return }
            store.replaceCredentialIdentities(identities) { _, error in
                if let error = error { print("Updating AutoFill suggestions failed: \(error)") }
            }
        }
    }
}
