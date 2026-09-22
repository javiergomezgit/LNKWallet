//
//  ServiceHost.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 9/22/26.
//

import Foundation

enum ServiceHost {

    // The host a saved website or an AutoFill service identifier refers to, in one comparable form:
    // "https://www.GitHub.com/login" → "github.com", "github.com" → "github.com", "" → nil.
    // Safari sends full URLs; saved items hold whatever the user typed (DataPasswordController adds https://).
    static func normalized(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard var host = URLComponents(string: withScheme)?.host?.lowercased() else { return nil }

        if host.hasPrefix("www.") {
            host.removeFirst(4)
        }
        return host.contains(".") ? host : nil
    }
}
