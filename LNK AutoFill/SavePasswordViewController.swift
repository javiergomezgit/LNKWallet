//
//  SavePasswordViewController.swift
//  LNK AutoFill
//
//  Created by Javier Gomez on 9/22/26.
//

import UIKit
import AuthenticationServices

// "Save to LNK Wallet": shown by iOS 26.2+ after a sign-in or sign-up, once the unlock gate passed.
// Prefilled from the request and editable. When the vault already has this site and user, it offers to
// update that item's password instead of creating a duplicate.
@available(iOS 26.2, *)
final class SavePasswordViewController: UIViewController {

    // MARK: — State
    var onSaved:  (() -> Void)?
    var onCancel: (() -> Void)?

    private let request:      ASSavePasswordRequest
    private let uid:          String
    private let creationDate: Int
    private let requestHost:  String?   // nil when an app, not a website, asked to save
    private let existing:     FillItem? // same site and user already in the vault
    private var isSaving      = false
    private var saveAttempt   = 0       // so a stale timeout can't fail a later retry

    private let scrollView      = UIScrollView()
    private let noticeLabel     = UILabel()
    private let nameField       = UITextField()
    private let userField       = UITextField()
    private let passwordField   = UITextField()
    private let websiteField    = UITextField()
    private let errorLabel      = UILabel()
    private let saveAsNewButton = UIButton(type: .system)
    private let spinner         = UIActivityIndicatorView(style: .medium)

    // MARK: — Lifecycle

    init(request: ASSavePasswordRequest, uid: String, creationDate: Int, items: [FillItem]?) {
        self.request      = request
        self.uid          = uid
        self.creationDate = creationDate

        let identifier   = request.serviceIdentifier
        let host         = identifier.type == .app ? nil : ServiceHost.normalized(identifier.identifier)
        self.requestHost = host
        self.existing    = items?.first { item in
            guard let host = host, let itemHost = item.host else { return false }
            return ServiceHost.matches(itemHost, host) &&
                   item.user.caseInsensitiveCompare(request.credential.user) == .orderedSame
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary
        hideKeyboardWhenTappedAround()

        setupNavBar()
        setupFields()
        setupLabels()
        setupLayout()
    }

    // MARK: — Setup

    private func setupNavBar() {
        styleFormNavBar(title: "autofill.save.title".localized())

        let cancelButton = UIBarButtonItem(title: "button.cancel".localized(),
                                           style: .plain,
                                           target: self,
                                           action: #selector(cancelTapped))
        cancelButton.tintColor = .textSecondary
        navigationItem.leftBarButtonItem = cancelButton

        let title      = existing == nil ? "button.save".localized() : "button.update".localized()
        let saveButton = UIBarButtonItem(title: title,
                                         style: .done,
                                         target: self,
                                         action: #selector(saveTapped))
        saveButton.tintColor = .accentBrand
        navigationItem.rightBarButtonItem = saveButton
    }

    private func setupFields() {
        let identifier = request.serviceIdentifier

        styleTextField(nameField,     placeholder: "autofill.save.name".localized())
        styleTextField(userField,     placeholder: "autofill.save.user".localized())
        styleTextField(passwordField, placeholder: "autofill.save.password".localized())
        styleTextField(websiteField,  placeholder: "autofill.save.website".localized())

        nameField.text     = existing?.name ?? request.title ?? identifier.displayName ?? requestHost
        userField.text     = request.credential.user
        passwordField.text = request.credential.password
        websiteField.text  = requestHost.map { "https://\($0)" }

        userField.autocapitalizationType    = .none
        userField.autocorrectionType        = .no
        userField.keyboardType              = .emailAddress
        passwordField.isSecureTextEntry     = true
        passwordField.autocorrectionType    = .no
        passwordField.enablePasswordToggle()
        websiteField.autocapitalizationType = .none
        websiteField.autocorrectionType     = .no
        websiteField.keyboardType           = .URL

        // Updating keeps the item's name, user and website; only the password changes
        [nameField, userField, websiteField].forEach { $0.isEnabled = existing == nil }
    }

    private func setupLabels() {
        noticeLabel.font          = UIFont.systemFont(ofSize: 14, weight: .regular)
        noticeLabel.textColor     = .textSecondary
        noticeLabel.numberOfLines = 0
        noticeLabel.isHidden      = existing == nil
        noticeLabel.text          = existing.map { "autofill.save.update_notice".localized(with: $0.host ?? $0.name) }

        errorLabel.font          = UIFont.systemFont(ofSize: 14, weight: .medium)
        errorLabel.textColor     = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden      = true

        saveAsNewButton.setTitle("autofill.save.as_new".localized(), for: .normal)
        saveAsNewButton.tintColor = .accentBrand
        saveAsNewButton.isHidden  = existing == nil
        saveAsNewButton.addTarget(self, action: #selector(saveAsNewTapped), for: .touchUpInside)

        spinner.color            = .accentBrand
        spinner.hidesWhenStopped = true
    }

    private func setupLayout() {
        let rows: [UIView] = [
            noticeLabel,
            caption("autofill.save.name"),     nameField,
            caption("autofill.save.user"),     userField,
            caption("autofill.save.password"), passwordField,
            caption("autofill.save.website"),  websiteField,
            errorLabel, saveAsNewButton, spinner
        ]
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis    = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(20, after: noticeLabel)
        [nameField, userField, passwordField].forEach { stack.setCustomSpacing(16, after: $0) }
        stack.setCustomSpacing(20, after: websiteField)

        scrollView.keyboardDismissMode = .interactive
        [scrollView, stack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        let fieldHeights = [nameField, userField, passwordField, websiteField].map {
            $0.heightAnchor.constraint(equalToConstant: 48)
        }
        NSLayoutConstraint.activate(fieldHeights + [
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func caption(_ key: String) -> UILabel {
        let label = UILabel()
        label.text      = key.localized().uppercased()
        label.font      = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .accentBrand
        return label
    }

    // MARK: — Actions

    @objc private func cancelTapped() {
        onCancel?()
    }

    @objc private func saveTapped() {
        if let existing = existing {
            updatePassword(of: existing)
        } else {
            saveNew()
        }
    }

    @objc private func saveAsNewTapped() {
        saveNew()
    }

    // MARK: — Data operations

    private func saveNew() {
        guard let decrypted = validatedInput() else { return }
        let documentID = decrypted.nameData.sanitizeNameForDB()

        setSaving(true)
        PasswordStore.add(encrypt(decrypted, documentID: documentID), uid: uid) { [weak self] saved in
            self?.finish(with: saved)
        }
    }

    private func updatePassword(of item: FillItem) {
        let newPassword = passwordField.text ?? ""
        guard !newPassword.isEmpty else {
            showError("autofill.save.missing_password".localized())
            return
        }
        guard let encryptedCurrent = AutoFillCache.read(uid: uid)?.first(where: { $0.documentID == item.documentID }) else {
            saveNew()
            return
        }

        let current = encryptedCurrent.decrypted(secretKey: uid, creationDate: creationDate)
        let updated = LNKDataPassword(nameData: current.nameData,
                                      email:    current.email,
                                      username: current.username,
                                      password: newPassword,
                                      website:  current.website)
        let encryptedUpdated = encrypt(updated, documentID: item.documentID)

        setSaving(true)
        PasswordStore.update(encryptedUpdated, uid: uid) { [weak self] success in
            self?.finish(with: success ? encryptedUpdated : nil)
        }
    }

    private func finish(with saved: PasswordRecord?) {
        // A late answer after the timeout already reported failure is ignored
        guard isSaving else { return }
        setSaving(false)

        guard let saved = saved else {
            showError("autofill.save.error".localized())
            return
        }
        updateOfflineCopy(with: saved)
        updateSuggestion(for: saved)
        onSaved?()
    }

    // Fills on the next visit without waiting for the app to refresh
    private func updateOfflineCopy(with encryptedSaved: PasswordRecord) {
        var encryptedRecords = AutoFillCache.read(uid: uid) ?? []
        encryptedRecords.removeAll { $0.documentID == encryptedSaved.documentID }
        encryptedRecords.append(encryptedSaved)
        AutoFillCache.write(encryptedRecords, uid: uid)
    }

    private func updateSuggestion(for encryptedSaved: PasswordRecord) {
        guard let identity = encryptedSaved.credentialIdentity(secretKey: uid, creationDate: creationDate) else { return }
        let store = ASCredentialIdentityStore.shared
        store.getState { state in
            guard state.isEnabled else { return }
            store.saveCredentialIdentities([identity]) { _, error in
                if let error = error { print("Saving AutoFill suggestion failed: \(error)") }
            }
        }
    }

    private func setSaving(_ saving: Bool) {
        isSaving = saving
        navigationItem.rightBarButtonItem?.isEnabled = !saving
        saveAsNewButton.isEnabled                    = !saving
        errorLabel.isHidden                          = true
        saving ? spinner.startAnimating() : spinner.stopAnimating()

        guard saving else { return }
        saveAttempt += 1
        let attempt  = saveAttempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self = self, self.saveAttempt == attempt else { return }
            self.finish(with: nil)
        }
    }

    // MARK: — Validation

    // The new item in plain text, laid out the way DataPasswordController saves it
    private func validatedInput() -> LNKDataPassword? {
        let name     = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let user     = (userField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.text ?? ""
        var website  = (websiteField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.sanitizeNameForDB().isEmpty else {
            showError("autofill.save.missing_name".localized())
            return nil
        }
        guard !password.isEmpty else {
            showError("autofill.save.missing_password".localized())
            return nil
        }
        if !website.isEmpty && !website.hasPrefix("http://") && !website.hasPrefix("https://") {
            website = "https://\(website)"
        }

        // One field in the form, two keys in the vault: key3 email, key2 username
        let isEmail = user.contains("@")
        return LNKDataPassword(nameData: name,
                               email:    isEmail ? user : "",
                               username: isEmail ? "" : user,
                               password: password,
                               website:  website)
    }

    private func showError(_ message: String) {
        errorLabel.text     = message
        errorLabel.isHidden = false
    }

    // MARK: — Encryption

    // Same call and key material as DataPasswordController.encryptDataPassword
    private func encrypt(_ decrypted: LNKDataPassword, documentID: String) -> PasswordRecord {
        let e = Encryption.shared.encryptDecrypt
        let p = String(creationDate)
        return PasswordRecord(documentID: documentID,
                              name:       e(decrypted.nameData, p, uid, true),
                              username:   e(decrypted.username, p, uid, true),
                              email:      e(decrypted.email,    p, uid, true),
                              password:   e(decrypted.password, p, uid, true),
                              website:    e(decrypted.website,  p, uid, true))
    }
}
