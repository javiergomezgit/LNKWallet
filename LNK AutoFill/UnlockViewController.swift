//
//  UnlockViewController.swift
//  LNK AutoFill
//
//  Created by Javier Gomez on 9/22/26.
//

import UIKit
import LocalAuthentication

// The gate in front of every password LNK AutoFill hands over. Face ID when the user turned it on in
// Settings, otherwise the master password, checked offline against the obfuscated copy the app keeps
// in the shared keychain. Wrong passwords count against the Settings limit; running out only locks
// the extension until the app is unlocked again. The extension never wipes the vault.
final class UnlockViewController: UIViewController {

    // MARK: — State
    var onUnlock: (() -> Void)?
    var onCancel: (() -> Void)?

    private let creationDate: Int?  // nil when nobody is signed in to the app
    private var didTryFaceID = false

    private let cancelButton  = UIButton(type: .system)
    private let logoView      = UIImageView(image: UIImage(named: "LogoIcon"))
    private let titleLabel    = UILabel()
    private let passwordField = UITextField()
    private let unlockButton  = UIButton(type: .system)
    private let faceIDButton  = UIButton(type: .system)
    private let messageLabel  = UILabel()

    private var faceIDEnabled: Bool {
        AppGroup.defaults?.bool(forKey: AppGroup.Key.unlockWithFaceID) ?? false
    }

    private var allowedAttempts: Int {
        let saved = AppGroup.defaults?.integer(forKey: AppGroup.Key.allowedAttempts) ?? 0
        return saved > 0 ? saved : 3
    }

    private var failedAttempts: Int {
        get { AppGroup.defaults?.integer(forKey: AppGroup.Key.failedAttempts) ?? 0 }
        set { AppGroup.defaults?.set(newValue, forKey: AppGroup.Key.failedAttempts) }
    }

    private var isLockedOut: Bool { failedAttempts >= allowedAttempts }

    private var encryptedMasterPassword: String? { SharedKeychain.string(for: .masterPassword) }

    // MARK: — Lifecycle

    init(creationDate: Int?) {
        self.creationDate = creationDate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary
        hideKeyboardWhenTappedAround()

        setupHeader()
        setupPasswordField()
        setupButtons()
        setupLayout()
        updateState(message: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if faceIDEnabled && !didTryFaceID && creationDate != nil {
            tryFaceID()
        } else if !passwordField.isHidden {
            passwordField.becomeFirstResponder()
        }
    }

    // MARK: — Setup

    private func setupHeader() {
        logoView.contentMode = .scaleAspectFit

        titleLabel.text          = "autofill.unlock.title".localized()
        titleLabel.font          = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor     = .textPrimary
        titleLabel.textAlignment = .center

        messageLabel.font          = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor     = .textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
    }

    private func setupPasswordField() {
        styleTextField(passwordField, placeholder: "autofill.unlock.placeholder".localized())
        // Same input traits as the app's master password field (Main.storyboard). Smart quotes or
        // dashes would turn ' into ’, which cleanPasswordCharacters then drops, and the check fails.
        passwordField.isSecureTextEntry      = true
        passwordField.keyboardType           = .asciiCapable
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType     = .no
        passwordField.spellCheckingType      = .no
        passwordField.smartQuotesType        = .no
        passwordField.smartDashesType        = .no
        passwordField.smartInsertDeleteType  = .no
        passwordField.returnKeyType          = .go
        passwordField.delegate               = self
        passwordField.enablePasswordToggle()
    }

    private func setupButtons() {
        stylePrimaryButton(unlockButton, title: "autofill.unlock.button".localized())
        unlockButton.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)

        var faceIDConfig           = UIButton.Configuration.plain()
        faceIDConfig.title         = "autofill.unlock.faceid".localized()
        faceIDConfig.image         = UIImage(systemName: "faceid")
        faceIDConfig.imagePadding  = 8
        faceIDButton.configuration = faceIDConfig
        faceIDButton.tintColor     = .accentBrand
        faceIDButton.addTarget(self, action: #selector(faceIDTapped), for: .touchUpInside)

        cancelButton.setTitle("button.cancel".localized(), for: .normal)
        cancelButton.tintColor = .textSecondary
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [logoView, titleLabel, passwordField, unlockButton, faceIDButton, messageLabel])
        stack.axis      = .vertical
        stack.spacing   = 16
        stack.alignment = .fill
        stack.setCustomSpacing(8, after: logoView)
        stack.setCustomSpacing(28, after: titleLabel)

        [cancelButton, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            stack.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            logoView.heightAnchor.constraint(equalToConstant: 64),
            passwordField.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // What the screen offers depends on sign-in, the stored copy, and the attempts left
    private func updateState(message: String?) {
        let signedIn    = creationDate != nil
        let canPassword = signedIn && encryptedMasterPassword != nil && !isLockedOut

        passwordField.isHidden = !canPassword
        unlockButton.isHidden  = !canPassword
        faceIDButton.isHidden  = !(signedIn && faceIDEnabled)

        if let message = message {
            messageLabel.text = message
        } else if !signedIn {
            messageLabel.text = "autofill.unlock.signed_out".localized()
        } else if isLockedOut {
            messageLabel.text = "autofill.unlock.locked_out".localized()
        } else if encryptedMasterPassword == nil {
            messageLabel.text = "autofill.unlock.no_copy".localized()
        } else {
            messageLabel.text = nil
        }
    }

    // MARK: — Actions

    @objc private func unlockTapped() {
        verifyMasterPassword()
    }

    @objc private func faceIDTapped() {
        tryFaceID()
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    // MARK: — Validation

    private func verifyMasterPassword() {
        guard let creationDate = creationDate, let encrypted = encryptedMasterPassword, !isLockedOut else {
            updateState(message: nil)
            return
        }

        // Same cleaning and decoding as MasterPasswordController.handleUnlock
        let typed     = passwordField.text?.cleanPasswordCharacters ?? ""
        let decrypted = EncryptionPassword.shared.encryptMasterPassword(
            encrypting: false,
            masterPassword: encrypted,
            timeStamp: creationDate)

        if !typed.isEmpty && typed == decrypted {
            failedAttempts = 0
            onUnlock?()
            return
        }

        failedAttempts    += 1
        passwordField.text = ""
        let remaining      = allowedAttempts - failedAttempts
        if remaining > 0 {
            updateState(message: "autofill.unlock.wrong".localized(with: remaining))
        } else {
            passwordField.resignFirstResponder()
            updateState(message: nil)
        }
    }

    private func tryFaceID() {
        didTryFaceID = true
        let context = LAContext()
        var error: NSError?
        guard faceIDEnabled, context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "autofill.unlock.faceid_reason".localized()) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    self.onUnlock?()
                } else if !self.passwordField.isHidden {
                    self.passwordField.becomeFirstResponder()
                }
            }
        }
    }
}

// MARK: — UITextFieldDelegate

extension UnlockViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        verifyMasterPassword()
        return false
    }
}
