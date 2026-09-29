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
