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

    // Whether a saved item's host belongs to the site being filled. Same registrable domain counts:
    // a github.com item fills on gist.github.com, a google.com item on accounts.google.com.
    // Both arguments must already be normalized.
    static func matches(_ savedHost: String, _ requestHost: String) -> Bool {
        savedHost == requestHost || registrableDomain(savedHost) == registrableDomain(requestHost)
    }

    // Common two-part public suffixes; without them every *.co.uk site would match every other.
    // Not the full Public Suffix List, which is too big to ship in the extension.
    private static let twoPartSuffixes: Set<String> = [
        "co.uk", "org.uk", "ac.uk", "gov.uk", "com.au", "net.au", "org.au", "co.nz", "co.jp", "ne.jp",
        "com.br", "com.mx", "com.ar", "com.co", "com.pe", "com.cn", "com.hk", "com.sg", "com.tr", "co.in",
        "co.kr", "co.za", "com.es", "com.tw", "gob.mx", "edu.mx", "org.mx"
    ]

    // "accounts.google.com" → "google.com", "www.bbc.co.uk" → "bbc.co.uk"
    static func registrableDomain(_ host: String) -> String {
        let labels = host.split(separator: ".").map(String.init)
        guard labels.count > 2 else { return host }
        let lastTwo = labels.suffix(2).joined(separator: ".")
        let keep    = twoPartSuffixes.contains(lastTwo) ? 3 : 2
        return labels.suffix(keep).joined(separator: ".")
    }
}
