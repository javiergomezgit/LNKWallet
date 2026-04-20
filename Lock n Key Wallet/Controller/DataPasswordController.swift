//
//  DataPasswordController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 7/2/22.
//

import UIKit
import FirebaseAuth

class DataPasswordController: UITableViewController {

    // MARK: — Outlets
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var otherTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var websiteTextField: UITextField!

    // MARK: — State
    public var nameData = ""
    var secretKey    = ""
    var creationDate = 0
    var user = Auth.auth().currentUser

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        view.backgroundColor       = .backgroundPrimary
        tableView.backgroundColor  = .backgroundPrimary
        tableView.separatorColor   = .border
        tableView.separatorInset   = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        setupNavBar()
        setupTextFields()
        setupUser()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.rightBarButtonItem?.title = nameData.isEmpty ? "button.save".localized() : "button.update".localized()
        self.title = nameData.isEmpty ? "datapassword.title.new".localized() : "datapassword.title".localized()

        if !nameData.isEmpty {
            titleTextField.text      = nameData
            titleTextField.isEnabled = false
            loadEncryptedDataPassword()
        }
    }

    // MARK: — Setup

    private func setupNavBar() {
        styleFormNavBar(title: "")

        let closeBtn = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(exitButtonTapped))
        closeBtn.tintColor = .textSecondary
        navigationItem.leftBarButtonItem = closeBtn

        let saveBtn = UIBarButtonItem(title: "button.save".localized(),
                                     style: .done,
                                     target: self,
                                     action: #selector(saveButtonTapped))
        saveBtn.tintColor = .accentBrand
        navigationItem.rightBarButtonItem = saveBtn
    }

    private func setupTextFields() {
        styleTextField(titleTextField,    placeholder: "datapassword.placeholder.name".localized(), accent: .accentBrand)
        styleTextField(emailTextField,    placeholder: "datapassword.placeholder.email".localized(), accent: .accentBrand)
        styleTextField(otherTextField,    placeholder: "datapassword.placeholder.other".localized(), accent: .accentBrand)
        styleTextField(passwordTextField, placeholder: "datapassword.placeholder.password".localized(), accent: .accentBrand)
        styleTextField(websiteTextField,  placeholder: "datapassword.placeholder.website".localized(), accent: .accentBrand)

        emailTextField.keyboardType              = .emailAddress
        emailTextField.autocapitalizationType    = .none
        emailTextField.textContentType           = .emailAddress

        passwordTextField.enablePasswordToggle()
        passwordTextField.layoutIfNeeded()
        passwordTextField.textContentType        = .password

        websiteTextField.keyboardType            = .URL
        websiteTextField.autocapitalizationType  = .none
        websiteTextField.autocorrectionType      = .no
        websiteTextField.textContentType         = .URL
    }

    private func setupUser() {
        guard let u = user else { exit(0) }
        secretKey    = u.uid
        creationDate = Int(u.metadata.creationDate!.timeIntervalSince1970)
    }

    // MARK: — Section headers

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titles = [
            "datapassword.section.account".localized(),
            "datapassword.section.credentials".localized(),
            "datapassword.section.details".localized()
        ]
        guard section < titles.count else { return nil }

        let container = UIView()
        container.backgroundColor = .backgroundPrimary

        let label = UILabel()
        label.text      = titles[section]
        label.font      = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .accentBrand
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        // Letter spacing via attributed string
        let attributed = NSMutableAttributedString(string: titles[section])
        attributed.addAttribute(.kern,
                                value: 0.8,
                                range: NSRange(location: 0, length: titles[section].count))
        label.attributedText = attributed
        label.font           = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor      = .accentBrand

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        return container
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .backgroundPrimary
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }

    // MARK: — Actions

    @IBAction func exitButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @objc private func saveButtonTapped() {
        nameData.isEmpty ? saveDataPassword() : updateDataPassword()
    }

    // MARK: — Data operations

    private func loadEncryptedDataPassword() {
        DBManager.shared.getEncryptedDataPassword(userID: user!.uid, nameData: nameData) { [weak self] data in
            guard let self = self, let data = data else { return }
            let d = self.decryptDataPassword(encryptedDataPassword: data)
            self.emailTextField.text    = d.email
            self.otherTextField.text    = d.username
            self.passwordTextField.text = d.password
            self.websiteTextField.text  = d.website
        }
    }

    private func saveDataPassword() {
        if let website = websiteTextField.text, !website.isEmpty,
           !website.hasPrefix("http://") && !website.hasPrefix("https://") {
            websiteTextField.text = "https://\(website)"
        }
        guard verifyPassFields(), let encrypted = encryptDataPassword() else { return }
        DBManager.shared.saveEncryptedDataPassword(
            nameOfData: titleTextField.text!.sanitizeNameForDB(),
            lnkDataPassword: encrypted,
            userID: user!.uid) { [weak self] success in
            guard let self = self, success else { return }
            self.dismiss(animated: true)
        }
    }

    private func updateDataPassword() {
        if let website = websiteTextField.text, !website.isEmpty,
           !website.hasPrefix("http://") && !website.hasPrefix("https://") {
            websiteTextField.text = "https://\(website)"
        }
        guard verifyPassFields(), let encrypted = encryptDataPassword() else { return }
        DBManager.shared.updateEncryptedDataPassword(
            nameOfData: titleTextField.text!.sanitizeNameForDB(),
            lnkDataPassword: encrypted,
            userID: user!.uid) { [weak self] success in
            guard let self = self, success else { return }
            self.showAlert(title: "alert.updated.title".localized(), message: "datapassword.updated.message".localized()) {
                self.dismiss(animated: true)
            }
        }
    }

    // MARK: — Validation

    private func verifyPassFields() -> Bool {
        if titleTextField.text?.isEmpty == true {
            showAlert(title: "alert.missing_name.title".localized(), message: "alert.missing_name.message".localized())
            return false
        }
        if passwordTextField.text?.isEmpty == true {
            showAlert(title: "alert.missing_password.title".localized(), message: "alert.missing_password.message".localized())
            return false
        }
        // Email validation — only if not empty
        if let email = emailTextField.text, !email.isEmpty {
            if !isValidEmail(email) {
                showAlert(title: "alert.invalid_email.title".localized(), message: "alert.invalid_email.message".localized())
                return false
            }
        }
        // Website validation — only if not empty
        if let website = websiteTextField.text, !website.isEmpty {
            if !isValidURL(website) {
                showAlert(title: "alert.invalid_website.title".localized(), message: "alert.invalid_website.message".localized())
                return false
            }
        }
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    private func isValidURL(_ url: String) -> Bool {
        // Auto-prefix https:// if missing
        let prefixed = url.hasPrefix("http://") || url.hasPrefix("https://") ? url : "https://\(url)"
        guard let components = URLComponents(string: prefixed),
              let host = components.host,
              !host.isEmpty,
              host.contains(".") else { return false }
        return true
    }

    // MARK: — Encryption

    private func encryptDataPassword() -> LNKDataPassword? {
        let e = Encryption.shared.encryptDecrypt
        let p = String(creationDate)
        return LNKDataPassword(
            nameData: e(titleTextField.text!,    p, secretKey, true),
            email:    e(emailTextField.text!,    p, secretKey, true),
            username: e(otherTextField.text!,    p, secretKey, true),
            password: e(passwordTextField.text!, p, secretKey, true),
            website:  e(websiteTextField.text!,  p, secretKey, true)
        )
    }

    private func decryptDataPassword(encryptedDataPassword c: LNKDataPassword) -> LNKDataPassword {
        let d = Encryption.shared.encryptDecrypt
        let p = String(creationDate)
        return LNKDataPassword(
            nameData: d(c.nameData, p, secretKey, false),
            email:    d(c.email,    p, secretKey, false),
            username: d(c.username, p, secretKey, false),
            password: d(c.password, p, secretKey, false),
            website:  d(c.website,  p, secretKey, false)
        )
    }

    // MARK: — Alert helper

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "button.ok".localized(), style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}
