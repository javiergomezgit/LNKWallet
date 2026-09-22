//
//  AppGroup.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 9/22/26.
//

import Foundation

// Identifiers shared by the app and LNK AutoFill. Must match both .entitlements files.
enum AppGroup {
    static let identifier          = "group.com.jdev.Lock-n-Key-Wallet"
    static let keychainAccessGroup = "SJK4QJY486.com.jdev.Lock-n-Key-Wallet.shared"

    // Settings the extension needs. The app keeps its own copies in UserDefaults.standard and
    // mirrors them here (AutoFillSync.syncPreferences).
    static let defaults = UserDefaults(suiteName: identifier)

    enum Key {
        static let unlockWithFaceID = "unlock_with_face_id"
        static let allowedAttempts  = "amount_attempts"
        static let failedAttempts   = "autofill_failed_attempts" // the extension's own counter
    }
}
