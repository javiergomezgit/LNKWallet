//
//  PasswordStore.swift
//  LNK AutoFill
//
//  Created by Javier Gomez on 9/22/26.
//

import FirebaseFirestore

// Writes password items to Firestore from LNK AutoFill, in the layout DBManager uses
// (PasswordRecord.fields). Takes and returns already-obfuscated records, like DBManager.
// The extension can't use DBManager itself: its CloudKit container needs an entitlement the
// extension doesn't have.
enum PasswordStore {

    private static let database: Firestore = {
        // No on-disk cache in the extension; writes either reach the server or report failure
        let settings           = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        let db                 = Firestore.firestore()
        db.settings            = settings
        return db
    }()

    private static func items(_ uid: String) -> CollectionReference {
        database.collection("User").document(uid).collection("secret_datas")
    }

    // New item. Same free-ID rule as DBManager.saveEncryptedDataPassword: name, name-2, name-3…
    // Completes with the record as saved (its final document ID), or nil.
    static func add(_ encrypted: PasswordRecord, uid: String, completion: @escaping (PasswordRecord?) -> Void) {
        availableDocumentID(uid: uid, baseName: encrypted.documentID) { documentID in
            guard let documentID = documentID else {
                completion(nil)
                return
            }
            let saved = PasswordRecord(documentID: documentID,
                                       name:       encrypted.name,
                                       username:   encrypted.username,
                                       email:      encrypted.email,
                                       password:   encrypted.password,
                                       website:    encrypted.website)
            items(uid).document(documentID).setData(saved.fields) { error in
                if let error = error { print("AutoFill save failed: \(error)") }
                completion(error == nil ? saved : nil)
            }
        }
    }

    // Existing item. Merging keeps fields this layout doesn't own, such as lastAccessed.
    static func update(_ encrypted: PasswordRecord, uid: String, completion: @escaping (Bool) -> Void) {
        items(uid).document(encrypted.documentID).setData(encrypted.fields, merge: true) { error in
            if let error = error { print("AutoFill update failed: \(error)") }
            completion(error == nil)
        }
    }

    private static func availableDocumentID(uid: String, baseName: String, suffix: Int = 1, completion: @escaping (String?) -> Void) {
        let candidate = suffix == 1 ? baseName : "\(baseName)-\(suffix)"
        items(uid).document(candidate).getDocument { snapshot, error in
            if let error = error {
                print("AutoFill name check failed: \(error)")
                completion(nil)
            } else if snapshot?.exists == true {
                availableDocumentID(uid: uid, baseName: baseName, suffix: suffix + 1, completion: completion)
            } else {
                completion(candidate)
            }
        }
    }
}
