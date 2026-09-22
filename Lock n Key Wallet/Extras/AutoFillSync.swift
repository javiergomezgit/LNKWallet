//
//  AutoFillSync.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 9/22/26.
//

import Foundation
import AuthenticationServices
import FirebaseAuth

// Keeps LNK AutoFill in step with the vault: the obfuscated offline copy it fills from, the
// QuickType suggestions iOS shows above the keyboard, and what its unlock screen needs. Call refresh()
// after anything that changes the password items, and clear() whenever the vault stops belonging to
// this device's user.
//
// The suggestions hold each item's domain and username in plaintext, in a system store on the
// device (never synced, never the password). Everything written to the App Group stays obfuscated.
enum AutoFillSync {

    static func refresh() {
        syncPreferences()
        guard let user = Auth.auth().currentUser, let created = user.metadata.creationDate else { return }
        let uid          = user.uid
        let creationDate = Int(created.timeIntervalSince1970)

        // Face ID users may never type their master password after this update; fetch the copy once
        if SharedKeychain.string(for: .masterPassword) == nil {
            DBManager.shared.downloadMasterPassword(userID: uid) { encryptedPassword in
                if let encryptedPassword = encryptedPassword {
                    storeMasterPasswordCopy(encryptedPassword)
                }
            }
        }

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
        SharedKeychain.removeAll()
        [AppGroup.Key.unlockWithFaceID, AppGroup.Key.allowedAttempts, AppGroup.Key.failedAttempts]
            .forEach { AppGroup.defaults?.removeObject(forKey: $0) }
        ASCredentialIdentityStore.shared.removeAllCredentialIdentities { _, error in
            if let error = error { print("Clearing AutoFill suggestions failed: \(error)") }
        }
    }

    // MARK: — Unlock

    // The obfuscated master password exactly as CloudKit returned it, so the extension can check a
    // typed password offline. Call wherever the app has just fetched or saved it.
    static func storeMasterPasswordCopy(_ encryptedPassword: String) {
        SharedKeychain.set(encryptedPassword, for: .masterPassword)
    }

    // Mirrors the Face ID switch and the attempts limit from Settings into the App Group
    static func syncPreferences() {
        let standard = UserDefaults.standard
        AppGroup.defaults?.set(standard.bool(forKey: "unlock_with_face_id"), forKey: AppGroup.Key.unlockWithFaceID)
        AppGroup.defaults?.set(standard.value(forKey: "amount_attempts") as? Int ?? 3, forKey: AppGroup.Key.allowedAttempts)
    }

    // A successful unlock in the app lifts a lock-out in the extension
    static func resetExtensionAttempts() {
        AppGroup.defaults?.set(0, forKey: AppGroup.Key.failedAttempts)
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
