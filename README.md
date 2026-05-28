# LNK Wallet

> A security-first iOS vault app for storing passwords, payment cards, images, and secure notes — all encrypted, none stored in plain text.

---
<img width="660" height="1434" alt="LNK Wallet-1" src="https://github.com/user-attachments/assets/c0ef0a2b-13ab-4d2c-a4b1-f4cc8b6f2862" />
<img width="660" height="1434" alt="LNK Wallet-2" src="https://github.com/user-attachments/assets/bb853ad4-e90c-49ea-9ae8-20c7b2e672b3" />
<img width="660" height="1434" alt="LNK Wallet-3" src="https://github.com/user-attachments/assets/aa1a1009-d9fe-4c87-9415-562e36c5d39f" />

<img width="800" height="1738" alt="LNK Wallet" src="https://github.com/user-attachments/assets/4b64c019-78d8-4f4c-90fa-c8dafd72b66d" />

---
## What it does

Lock N Key Wallet lets users store their most sensitive personal data behind a master password and biometric authentication. Every piece of data is encrypted before it leaves the device.

- **Passwords** — store login credentials with username, email, password, and website
- **Payment cards** — store card details with optional camera scanner for instant capture
- **Images** — encrypted image storage with a split-storage architecture across Apple and Firebase infrastructure
- **Secure notes** — encrypted freeform text notes

---

## Architecture

| Layer | Technology |
|---|---|
| Platform | iOS (UIKit, Swift) |
| Backend | Firebase (Auth, Firestore, Storage) |
| Encryption | AES-based via custom `Encryption` service |
| Dependency management | CocoaPods |

### Image storage model

Image data is decomposed into raw bytes, split into two chunks, and stored across separate server infrastructure (Apple + Firebase). No single server ever holds a complete image.

---

## Security model

- All text data (passwords, card details, notes) is encrypted before writing to Firestore
- Encryption keys are derived from user UID and account creation timestamp — never stored in plain text
- Images are encrypted and split across two separate storage backends
- Master password and biometric lock on every app launch
- Auto-lock on background
- Configurable erase-after-failed-attempts in Settings
- No unencrypted user data stored on any third-party server

---

## Screens

- **My Vault** — home screen with 4 category cards and recently accessed items
- **Category list** — filtered list per category with search
- **Add / Edit forms** — per data type (passwords, cards, images, notes)
- **Tools** — password generator and password health checker
- **Settings** — security configuration and account management

---

## Requirements

- iOS 15.0+
- Xcode 14+
- CocoaPods
- Firebase project with Auth, Firestore, and Storage enabled

---

## Setup

```bash
git clone https://github.com/javiergomezgit/LNKWallet.git
cd lnk-wallet
pod install
open "Lock n Key Wallet.xcworkspace"
```

Add your `GoogleService-Info.plist` to the project root before building.

> Note: The app will not build without a valid Firebase configuration file. Never commit `GoogleService-Info.plist` to version control.

---

## Project structure

```
Lock n Key Wallet/
├── AppDelegate.swift
├── Controllers/
│   ├── VaultHomeViewController.swift
│   ├── OpenVaultController.swift
│   ├── DataPasswordController.swift
│   ├── DataCreditCardController.swift
│   ├── DataImageController.swift
│   └── DataSecureNoteController.swift
├── Cells/
│   ├── DatasViewCell.swift
│   ├── CategoryCardCell.swift
│   └── RecentItemCell.swift
├── Models/
│   └── LNKData.swift
├── Services/
│   ├── DBManager.swift
│   └── Encryption.swift
├── Extensions/
│   └── UIViewController+FormStyle.swift
├── Enums/
│   └── VaultCategory.swift
└── Resources/
    ├── Assets.xcassets/
    └── Vault.storyboard
```

---

## Color system

| Token | Light | Dark | Usage |
|---|---|---|---|
| `backgroundPrimary` | `#FFFFFF` | `#1A1A1A` | Main screen backgrounds |
| `backgroundSecondary` | `#F5F4F0` | `#242424` | Cards, inputs, surfaces |
| `backgroundChrome` | `#F5F4F0` | `#0F0F0F` | Tab bar, nav bar |
| `textPrimary` | `#1A1A1A` | `#F0F0F0` | Headings, body text |
| `textSecondary` | `#ABABAB` | `#555555` | Labels, placeholders |
| `border` | `#E0DED8` | `#2A2A2A` | Dividers, field borders |
| `accentBrand` | `#C9A84C` | `#C9A84C` | Primary brand, passwords |
| `accentCards` | `#378ADD` | `#378ADD` | Payment cards |
| `accentImages` | `#1D9E75` | `#1D9E75` | Images |
| `accentNotes` | `#D4537E` | `#D4537E` | Secure notes |

---

## Status

Active development — MVP targeting App Store submission within 3 months.

---

## License

Private repository. All rights reserved.
