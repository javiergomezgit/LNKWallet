//
//  VaultCategory.swift.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 4/1/26.
//

import UIKit

enum VaultCategory: CaseIterable {
    case passwords, cards, images, notes

    var title: String {
        switch self {
        case .passwords: return "category.passwords".localized()
        case .cards:     return "category.cards".localized()
        case .images:    return "category.images".localized()
        case .notes:     return "category.notes".localized()
        }
    }

    // Maps to your existing Firestore type keys
    var typeKey: String {
        switch self {
        case .passwords: return "type_2"
        case .cards:     return "type_1"
        case .images:    return "type_4"
        case .notes:     return "type_3"
        }
    }

    var accent: UIColor {
        switch self {
        case .passwords: return .accentBrand
        case .cards:     return .accentCards
        case .images:    return .accentImages
        case .notes:     return .accentNotes
        }
    }

    var icon: UIImage? {
        switch self {
        case .passwords: return UIImage(systemName: "lock.fill")
        case .cards:     return UIImage(systemName: "creditcard.fill")
        case .images:    return UIImage(systemName: "photo.fill")
        case .notes:     return UIImage(systemName: "doc.text.fill")
        }
    }
}
