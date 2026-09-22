//
//  PasswordGenerator.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 9/22/26.
//

import Foundation
import Security

// Random passwords for the Tools generator and for LNK AutoFill's "strong password" suggestions.
// One random source for both: SecRandomCopyBytes with rejection sampling, so every character in
// the set is equally likely.
enum PasswordGenerator {

    static let lowercase = "abcdefghijklmnopqrstuvwxyz"
    static let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static let digits    = "0123456789"
    static let symbols   = "~!@#$%^&*().,_+=-<>?"

    // The Tools generator: lowercase plus whichever classes are switched on
    static func generate(length: Int, uppercase: Bool, digits: Bool, symbols: Bool) -> String {
        var charset = lowercase
        if uppercase { charset += self.uppercase }
        if digits    { charset += self.digits }
        if symbols   { charset += self.symbols }
        return randomString(length: length, from: Array(charset))
    }

    // A password the site will accept: within its length limits, only allowed characters, at least one
    // from each required set, no longer runs of one character than it allows. nil if the rules can't
    // be met from `charset` (e.g. alphanumeric only, but the site requires a symbol).
    static func generate(following rules: PasswordRules, length preferred: Int = 20,
                         limitedTo charset: Set<Character>? = nil) -> String? {
        let allowed  = charset.map { rules.allowed.intersection($0) } ?? rules.allowed
        let required = rules.required.map { $0.intersection(allowed) }
        guard !allowed.isEmpty, !required.contains(where: { $0.isEmpty }) else { return nil }

        let length = max(rules.minLength ?? 0, min(preferred, rules.maxLength ?? preferred))
        guard length >= required.count else { return nil }

        let characters = Array(allowed).sorted()
        for _ in 0..<200 {
            let candidate = randomString(length: length, from: characters)
            if rules.accepts(candidate) { return candidate }
        }
        return nil
    }

    // Uniform picks from `characters` (at most 256). Bytes at or above the largest multiple of the
    // set size are thrown away, so no character is favoured by the modulo.
    static func randomString(length: Int, from characters: [Character]) -> String {
        precondition(!characters.isEmpty && characters.count <= 256)
        let limit  = 256 - (256 % characters.count)
        var picked = [Character]()
        picked.reserveCapacity(length)

        while picked.count < length {
            var bytes  = [UInt8](repeating: 0, count: 32)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            guard status == errSecSuccess else { fatalError("SecRandomCopyBytes failed: \(status)") }

            for byte in bytes where Int(byte) < limit && picked.count < length {
                picked.append(characters[Int(byte) % characters.count])
            }
        }
        return String(picked)
    }
}

// A site's password rules in Apple's passwordrules format, e.g.
// "minlength: 8; maxlength: 16; required: lower; required: upper, digit; allowed: [-_!];"
// Each `required:` needs at least one character from the union of its classes.
struct PasswordRules {
    var minLength:      Int?
    var maxLength:      Int?
    var maxConsecutive: Int?
    var required:       [Set<Character>] = []
    var allowed:        Set<Character>   = []

    private static let special        = Set("-~!@#$%^&*_+=`|(){}[:;\"'<>,.?]")
    private static let asciiPrintable = Set((0x21...0x7E).compactMap { UnicodeScalar($0).map(Character.init) })

    // With no rules from the site: lowercase, uppercase, digit and symbol, one of each
    static let `default` = PasswordRules(parsing: nil)

    init(parsing text: String?) {
        let properties = (text ?? "")
            .split(separator: ";")
            .compactMap { property -> (String, String)? in
                let parts = property.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                return parts.count == 2 ? (parts[0].lowercased(), parts[1]) : nil
            }

        for (name, value) in properties {
            switch name {
            case "minlength":       minLength      = Int(value)
            case "maxlength":       maxLength      = Int(value)
            case "max-consecutive": maxConsecutive = Int(value)
            case "required":        required.append(Self.characters(in: value))
            case "allowed":         allowed.formUnion(Self.characters(in: value))
            default:                break
            }
        }

        if required.isEmpty && allowed.isEmpty {
            required = [Set(PasswordGenerator.lowercase), Set(PasswordGenerator.uppercase),
                        Set(PasswordGenerator.digits),    Set(PasswordGenerator.symbols)]
        }
        // Required characters are always allowed
        required.forEach { allowed.formUnion($0) }
    }

    func accepts(_ password: String) -> Bool {
        if let minLength = minLength, password.count < minLength { return false }
        if let maxLength = maxLength, password.count > maxLength { return false }
        guard password.allSatisfy(allowed.contains) else { return false }
        guard required.allSatisfy({ set in password.contains(where: set.contains) }) else { return false }

        if let maxConsecutive = maxConsecutive, maxConsecutive > 0 {
            var run = 0
            var previous: Character?
            for character in password {
                run      = character == previous ? run + 1 : 1
                previous = character
                if run > maxConsecutive { return false }
            }
        }
        return true
    }

    // "upper, digit, [-_!]" → the union of those classes. `unicode` is treated as printable ASCII.
    private static func characters(in value: String) -> Set<Character> {
        var result = Set<Character>()
        var rest   = Substring(value)

        while !rest.isEmpty {
            rest = rest.drop { $0 == " " || $0 == "," }
            guard !rest.isEmpty else { break }

            if rest.first == "[", let close = rest.lastIndex(of: "]") {
                result.formUnion(rest[rest.index(after: rest.startIndex)..<close])
                rest = rest[rest.index(after: close)...]
                continue
            }
            let token = rest.prefix { $0 != "," }
            rest      = rest.dropFirst(token.count)
            switch token.trimmingCharacters(in: .whitespaces).lowercased() {
            case "upper":                      result.formUnion(PasswordGenerator.uppercase)
            case "lower":                      result.formUnion(PasswordGenerator.lowercase)
            case "digit":                      result.formUnion(PasswordGenerator.digits)
            case "special":                    result.formUnion(special)
            case "ascii-printable", "unicode": result.formUnion(asciiPrintable)
            default:                           break
            }
        }
        return result
    }
}
