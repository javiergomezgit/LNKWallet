//
//  AutoFillCache.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 9/22/26.
//

import Foundation

// LNK AutoFill's offline copy of the password items, written by the app. Values stay obfuscated
// exactly as in Firestore. Only the app and the extension can open the App Group container, and
// complete file protection keeps it unreadable while the device is locked.
enum AutoFillCache {

    private struct Snapshot: Codable {
        let uid:     String
        let records: [PasswordRecord]
    }

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)?
            .appendingPathComponent("autofill_passwords.json")
    }

    @discardableResult
    static func write(_ encryptedRecords: [PasswordRecord], uid: String) -> Bool {
        guard let url = fileURL else {
            print("AutoFill cache write failed: App Group container unavailable")
            return false
        }
        do {
            let data = try JSONEncoder().encode(Snapshot(uid: uid, records: encryptedRecords))
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return true
        } catch {
            print("AutoFill cache write failed: \(error)")
            return false
        }
    }

    // nil when there is no copy yet, or it belongs to a different account
    static func read(uid: String) -> [PasswordRecord]? {
        guard
            let url      = fileURL,
            let data     = try? Data(contentsOf: url),
            let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data),
            snapshot.uid == uid
        else { return nil }
        return snapshot.records
    }

    static func clear() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
