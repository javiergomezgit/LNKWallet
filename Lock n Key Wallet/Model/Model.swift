//
//  Model.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/23/21.
//

import Foundation
import CloudKit

struct LockData {
    let nameData: String
    let nameOnCard: String
    let numberCard: String
    let expDate: String
    let securityCode: String
}

struct LockDataPassword {
    let nameData: String
    let username: String?
    let email: String?
    let password: String
}

struct LNKData {
    let nameData: String
    let userData: String?
    let contentData: String
}
