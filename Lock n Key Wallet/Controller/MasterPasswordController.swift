//
//  PasscodeController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/23/21.
//

import UIKit
import FirebaseAuth
import CloudKit

class MasterPasswordController: UIViewController {

    // MARK: — Outlets
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var passwordButton: UIButton!
    @IBOutlet weak var requirementsLabel: UILabel!

    // MARK: — State
    var setPassword      = true
    var temporalPassword = ""

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTextField()
        setupButton()
        setupRequirementsLabel()
        self.hideKeyboardWhenTappedAround()
        passwordText.addTarget(self,
                               action: #selector(textFieldDidChange(_:)),
                               for: .editingChanged)

        let hasPassword = UserDefaults.standard.bool(forKey: "found_passcode")
        if hasPassword {
            setPassword = false
            updateUI(placeholder: "Type Password", buttonTitle: "Unlock")
        } else {
            setPassword = true
            updateUI(placeholder: "Set Master Password", buttonTitle: "Set Password")
            // Only fetch from CloudKit if we don't know yet
            downloadMasterPassword()
        }
    }

    // MARK: — Setup

    private func setupTextField() {
        passwordText.backgroundColor    = UIColor.white.withAlphaComponent(0.4)
        passwordText.layer.cornerRadius = 12
        passwordText.layer.borderWidth  = 0
        passwordText.textColor          = .black
        passwordText.tintColor          = .black
        passwordText.font               = UIFont.systemFont(ofSize: 16, weight: .regular)
        passwordText.borderStyle        = .none
        passwordText.autocapitalizationType = .none
        passwordText.autocorrectionType     = .no

        // Padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        passwordText.leftView     = paddingView
        passwordText.leftViewMode = .always

        passwordText.attributedPlaceholder = NSAttributedString(
            string: setPassword ? "Set Master Password" : "Type Password",
            attributes: [.foregroundColor: UIColor.black.withAlphaComponent(0.5)]
        )

        passwordText.enablePasswordToggle()
    }

    private func setupButton() {
        passwordButton.isEnabled        = false
        passwordButton.alpha            = 0.75
        passwordButton.setTitleColor(.white, for: .normal)
        passwordButton.setTitleColor(.white, for: .disabled)
        passwordButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        passwordButton.layer.cornerRadius = 14
        passwordButton.layer.backgroundColor = UIColor.black.cgColor
        passwordButton.setTitle(setPassword ? "Set Password" : "Unlock", for: .normal)
    }

    private func setupRequirementsLabel() {
        requirementsLabel.text      = "Must have: 1 capital letter, 1 symbol & at least 8 characters."
        requirementsLabel.font      = UIFont.systemFont(ofSize: 13, weight: .regular)
        requirementsLabel.textColor = UIColor.black.withAlphaComponent(0.6)
        requirementsLabel.numberOfLines = 0
        requirementsLabel.alpha     = 0.9
    }

    // MARK: — Data

    private func downloadMasterPassword() {
        guard let user = Auth.auth().currentUser else { return }
        DBManager.shared.downloadMasterPassword(userID: user.uid) { [weak self] encryptedPassword in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if encryptedPassword == nil {
                    self.setPassword = true
                    self.updateUI(placeholder: "Set Master Password", buttonTitle: "Set Password")
                } else {
                    self.setPassword = false
                    self.updateUI(placeholder: "Type Password", buttonTitle: "Unlock")
                }
            }
        }
    }

    private func updateUI(placeholder: String, buttonTitle: String) {
        passwordText.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.black.withAlphaComponent(0.5)]
        )
        passwordButton.setTitle(buttonTitle, for: .normal)
    }

    // MARK: — Actions

    @IBAction func passwordButtonTapped(_ sender: Any) {
        let cleanPassword = passwordText.text!.cleanPasswordCharacters
        guard let user = Auth.auth().currentUser else { return }
        let timeStamp = Int(user.metadata.creationDate!.timeIntervalSince1970)
        UserDefaults.standard.set(timeStamp, forKey: "date_creation_user")

        if setPassword {
            handleSetPassword(cleanPassword: cleanPassword, user: user, timeStamp: timeStamp)
        } else {
            handleUnlock(cleanPassword: cleanPassword, user: user, timeStamp: timeStamp)
        }
    }

    private func handleSetPassword(cleanPassword: String, user: User, timeStamp: Int) {
        if temporalPassword.isEmpty {
            temporalPassword = cleanPassword
            passwordText.text = ""
            updateUI(placeholder: "Verify Password", buttonTitle: "Verify Password")
            passwordButton.isEnabled = false
            passwordButton.alpha     = 0.5
        } else {
            if cleanPassword == temporalPassword {
                let encrypted = EncryptionPassword.shared.encryptMasterPassword(
                    encrypting: true,
                    masterPassword: cleanPassword,
                    timeStamp: timeStamp)
                DBManager.shared.saveMasterPassword(userID: user.uid,
                                                    encryptedPassword: encrypted) { [weak self] success in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        if success {
                            UserDefaults.standard.set(false, forKey: "locked_app")
                            self.dismiss(animated: true)
                        } else {
                            self.showAlert(title: "Error",
                                          message: "Couldn't save your master password. Please try again.")
                        }
                    }
                }
            } else {
                temporalPassword = ""
                passwordText.text = ""
                updateUI(placeholder: "Set Master Password", buttonTitle: "Set Password")
                showAlert(title: "Passwords don't match",
                          message: "Please try again.")
            }
        }
    }

    private func handleUnlock(cleanPassword: String, user: User, timeStamp: Int) {
        DBManager.shared.downloadMasterPassword(userID: user.uid) { [weak self] encryptedPassword in
            guard let self = self else { return }

            guard let encrypted = encryptedPassword else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Connection Issue",
                                  message: "Unable to verify your password right now. Please wait a moment and try again.")
                }
                return
            }

            let decrypted = EncryptionPassword.shared.encryptMasterPassword(
                encrypting: false,
                masterPassword: encrypted,
                timeStamp: timeStamp)

            DispatchQueue.main.async {
                if cleanPassword == decrypted {
                    UserDefaults.standard.set(false, forKey: "locked_app")
                    self.dismiss(animated: true)
                } else {
                    self.passwordText.text = ""
                    let attempts  = UserDefaults.standard.value(forKey: "amount_attempts") as! Int
                    var attempted = UserDefaults.standard.value(forKey: "attempted_failed") as! Int

                    if attempted < attempts {
                        attempted += 1
                        UserDefaults.standard.set(attempted, forKey: "attempted_failed")
                        let remaining = (attempts + 1) - attempted
                        self.showAlert(title: "Wrong password",
                                      message: "Your data will be erased after \(remaining) more failed attempt\(remaining == 1 ? "" : "s").")
                    } else {
                        DBManager.shared.deleteAllDatas(userID: user.uid) { success in
                            guard success else { return }
                            UserDefaults.standard.set(3, forKey: "amount_attempts")
                            UserDefaults.standard.set(0, forKey: "attempted_failed")
                            UserDefaults.standard.set(true, forKey: "locked_app")
                            exit(0)
                        }
                    }
                }
            }
        }
    }

    // MARK: — Text field validation

    @objc func textFieldDidChange(_ textField: UITextField) {
        if !setPassword {
                let hasText = !(textField.text?.isEmpty ?? true)
                passwordButton.isEnabled = hasText
                passwordButton.alpha     = hasText ? 1.0 : 0.5
                return
            }

            // Set password mode — full validation
            let text      = textField.text ?? ""
            let hasUpper  = text.hasCharacter(in: .uppercaseLetters)
            let hasSymbol = text.hasCharacter(in: .punctuationCharacters)
            let hasLength = text.count > 8
            let isValid   = hasUpper && hasSymbol && hasLength

            passwordButton.isEnabled = isValid
            passwordButton.alpha     = isValid ? 1.0 : 0.5
            requirementsLabel.alpha  = isValid ? 0.4 : 0.7
    }

    // MARK: — Alert helper

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}
