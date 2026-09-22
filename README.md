# LNK Wallet

An iOS vault app for passwords, payment cards, images, and secure notes. Everything
is obfuscated on-device before it is written to the backend, behind a master password
and optional Face ID.

<table>
  <tr>
    <td><img width="220" alt="LNK Wallet-1" src="https://github.com/user-attachments/assets/c0ef0a2b-13ab-4d2c-a4b1-f4cc8b6f2862" /></td>
    <td><img width="220" alt="LNK Wallet-2" src="https://github.com/user-attachments/assets/bb853ad4-e90c-49ea-9ae8-20c7b2e672b3" /></td>
    <td><img width="220" alt="LNK Wallet-3" src="https://github.com/user-attachments/assets/aa1a1009-d9fe-4c87-9415-562e36c5d39f" /></td>
  </tr>
</table>

## Features

- **Passwords** — name, email, username, password, website
- **Payment cards** — card details with a camera scanner for instant capture
- **Images** — photo-library or camera capture, obfuscated before upload
- **Secure notes** — freeform text, obfuscated like everything else
- **Tools** — password generator and a password-health check (weak / reused)
- **Lock** — master password on launch and on return from background, optional
  Face ID unlock, and a configurable wipe after N failed attempts
- **Password AutoFill** (2.1.0) — LNK Wallet is a system password provider: logins
  appear above the keyboard in Safari and apps and fill after Face ID or the master
  password. On iOS 26.2+ it also offers to save new logins and suggests strong
  passwords that follow each site's rules
- English and Spanish

## Tech stack

UIKit + storyboards, Swift 5, iOS 17.0 minimum. The `LNK AutoFill` credential provider
extension needs iOS 17.6; saving and generating passwords from it need iOS 26.2. Sign
in with Apple for authentication. Firebase (Auth, Firestore, Storage) for item data, CloudKit for the
master password. Dependencies are Swift Package Manager only — **there is no
CocoaPods in this project** and no `.xcworkspace`.

## Build

```bash
open "Lock n Key Wallet.xcodeproj"
```

Xcode resolves the packages on first open; build the `Lock n Key Wallet` scheme.

**A fresh clone will not compile.** Six files the app needs are gitignored and are
not in the repository:

- `Lock n Key Wallet/Resources/Info.plist`
- `Lock n Key Wallet/Resources/GoogleService-Info.plist`
- `LNK AutoFill/GoogleService-Info.plist` (the same file as the app's)
- `Lock n Key Wallet/Controller/DBControllers/DBManager.swift`
- `Lock n Key Wallet/Extras/Encryption/Encryption.swift`
- `Lock n Key Wallet/Extras/Encryption/EncryptionPassword.swift`

Copy them in from a machine that already has them before building. The two
encryption files also define the stored-data format, so replacements are not
interchangeable — an unlike-for-like copy makes existing vault data unreadable.

Signing needs an Apple Developer team with the iCloud container
`iCloud.com.jdev.Lock-n-Key-Wallet`, the Sign in with Apple capability, and — on both
the app and the extension — the AutoFill Credential Provider capability, the App Group
`group.com.jdev.Lock-n-Key-Wallet` and the keychain group
`com.jdev.Lock-n-Key-Wallet.shared`. Automatic signing sets these up.

## License

Private repository. All rights reserved.
