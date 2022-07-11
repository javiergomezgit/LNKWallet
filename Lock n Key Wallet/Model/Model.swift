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
