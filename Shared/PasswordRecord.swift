//
//  PasswordRecord.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 9/22/26.
//

import Foundation
import AuthenticationServices

// One password item exactly as stored in User/{uid}/secret_datas: the plaintext document ID plus
// the obfuscated key1…key5. The single definition of the password field order, shared by
// DBManager, the AutoFill cache and LNK AutoFill.
struct PasswordRecord: Codable, Equatable {
    static let typeKey = "type_2"

    let documentID: String
    let name:       String // key1
    let username:   String // key2
    let email:      String // key3
    let password:   String // key4
    let website:    String // key5

    init(documentID: String, name: String, username: String, email: String, password: String, website: String) {
        self.documentID = documentID
        self.name       = name
        self.username   = username
        self.email      = email
        self.password   = password
        self.website    = website
    }

    // nil for anything that isn't a well-formed password document
    init?(documentID: String, fields: [String: Any]) {
        guard
            fields["key0"] as? String == Self.typeKey,
            let name     = fields["key1"] as? String,
            let username = fields["key2"] as? String,
            let email    = fields["key3"] as? String,
            let password = fields["key4"] as? String,
            let website  = fields["key5"] as? String
        else { return nil }
        self.init(documentID: documentID, name: name, username: username, email: email, password: password, website: website)
    }

    var fields: [String: String] {
        ["key0": Self.typeKey,
         "key1": name,
         "key2": username,
         "key3": email,
         "key4": password,
         "key5": website]
    }

    // Same call and key material as DataPasswordController / PasswordHealthViewController
    func decrypted(secretKey: String, creationDate: Int) -> LNKDataPassword {
        let d = Encryption.shared.encryptDecrypt
        let p = String(creationDate)
        return LNKDataPassword(
            nameData: d(name,     p, secretKey, false),
            email:    d(email,    p, secretKey, false),
            username: d(username, p, secretKey, false),
            password: d(password, p, secretKey, false),
            website:  d(website,  p, secretKey, false)
        )
    }

    // The QuickType suggestion for this item: its website's host, the username (or the email when
    // there is none), and the document ID so LNK AutoFill can fill the exact item. nil without a
    // website or a user. The host and user end up in plaintext in the system's identity store.
    func credentialIdentity(secretKey: String, creationDate: Int) -> ASPasswordCredentialIdentity? {
        let decryptedItem = decrypted(secretKey: secretKey, creationDate: creationDate)
        guard let host = ServiceHost.normalized(decryptedItem.website) else { return nil }

        let user = decryptedItem.username.isEmpty ? decryptedItem.email : decryptedItem.username
        guard !user.isEmpty else { return nil }

        return ASPasswordCredentialIdentity(
            serviceIdentifier: ASCredentialServiceIdentifier(identifier: host, type: .domain),
            user:              user,
            recordIdentifier:  documentID)
    }
}
