//
//  Model.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/23/21.
//

import Foundation

struct LNKDataCreditCard {
    let nameData: String
    let nameOnCard: String
    let numberCard: String
    let securityCode: String
    let zipCode: String
    let expDate: String
    let address: String
}

struct LNKDataPassword {
    let nameData: String
    let email: String
    let username: String
    let password: String
    let website: String
}

struct LNKDataSecureNote {
    let nameData: String
    let secureNote: String
}

struct LNKDataImage {
    let nameData: String
    let urlData: String
    let imageData: Data
}

struct LNKData {
    let nameData: String
    let typeData: String
}

// Outcome of looking up the user's master password record in CloudKit. Only `.notFound`
// means the user never set one; every other failure must leave the app in unlock mode.
enum MasterPasswordLookup {
    case found(String)  // obfuscated master password, exactly as stored
    case notFound       // no record for this user
    case unreadable     // record exists but this iCloud account may not read it (created by another one)
    case failed         // network, iCloud signed out, server error
}

// Outcome of checking the signed-in user's own profile document. Only `.missing` means the account
// is gone; a failed check must never sign the user out.
enum UserProfileLookup {
    case exists
    case missing  // no User/{uid} document
    case failed   // network, permissions, server error
}

// How long a copied password stays on the clipboard (Settings › Clear Copied Passwords). Raw value
// is seconds; 0 means it is never cleared. Copies are always kept to this device.
enum ClipboardClearDelay: Int, CaseIterable {
    case seconds30 = 30
    case minute1   = 60
    case minutes2  = 120
    case minutes5  = 300
    case never     = 0

    static let defaultsKey = "clipboard_clear_seconds"

    static var current: ClipboardClearDelay {
        get {
            guard let saved = UserDefaults.standard.object(forKey: defaultsKey) as? Int else { return .minute1 }
            return ClipboardClearDelay(rawValue: saved) ?? .minute1
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }

    var title: String {
        switch self {
        case .seconds30: return "settings.clipboard.30s".localized()
        case .minute1:   return "settings.clipboard.1m".localized()
        case .minutes2:  return "settings.clipboard.2m".localized()
        case .minutes5:  return "settings.clipboard.5m".localized()
        case .never:     return "settings.clipboard.never".localized()
        }
    }
}

extension Notification.Name {
    // Posted after an item is saved or updated. The editors are sheets, and closing a sheet doesn't
    // call viewWillAppear on the list underneath, so lists listen for this to reload.
    static let vaultDidChange = Notification.Name("vaultDidChange")
}

// Wrong master passwords typed in the app (LNK AutoFill keeps its own count and never erases).
// At the limit set in Settings the unlock waits, growing with each further miss, or, only if the
// user opted in, the vault is erased. A correct unlock or Face ID resets everything.
enum UnlockAttempts {
    enum Outcome {
        case tryAgain(remaining: Int)
        case lockedOut(TimeInterval)
        case erase
    }

    static let lockoutSteps: [TimeInterval] = [60, 300, 900, 3600]
    static let eraseKey = "erase_after_failed_attempts"

    private static let defaults = UserDefaults.standard

    static var limit: Int {
        defaults.object(forKey: "amount_attempts") as? Int ?? 3
    }

    static var eraseVaultAtLimit: Bool {
        get { defaults.bool(forKey: eraseKey) }
        set { defaults.set(newValue, forKey: eraseKey) }
    }

    // Seconds left before the master password can be tried again; 0 when not locked out
    static var lockoutRemaining: TimeInterval {
        max(0, defaults.double(forKey: "lockout_until") - Date().timeIntervalSince1970)
    }

    static func recordFailure() -> Outcome {
        let failed = (defaults.object(forKey: "attempted_failed") as? Int ?? 0) + 1
        if failed < limit {
            defaults.set(failed, forKey: "attempted_failed")
            return .tryAgain(remaining: limit - failed)
        }
        if eraseVaultAtLimit { return .erase }

        let level = defaults.object(forKey: "lockout_level") as? Int ?? 0
        let wait  = lockoutSteps[min(level, lockoutSteps.count - 1)]
        defaults.set(level + 1, forKey: "lockout_level")
        defaults.set(Date().timeIntervalSince1970 + wait, forKey: "lockout_until")
        // After a wait, every further miss locks again with the next, longer wait
        defaults.set(limit - 1, forKey: "attempted_failed")
        return .lockedOut(wait)
    }

    static func reset() {
        ["attempted_failed", "lockout_level", "lockout_until"].forEach { defaults.removeObject(forKey: $0) }
    }
}
