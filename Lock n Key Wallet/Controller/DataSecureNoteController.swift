//
//  DataSecureNoteController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 7/4/22.
//

import UIKit
import FirebaseAuth

class DataSecureNoteController: UITableViewController {

    // MARK: — Outlets
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var secureNoteTextView: UITextView!

    // MARK: — State
    public var nameData  = ""
    var secretKey        = ""
    var creationDate     = 0

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        view.backgroundColor      = .backgroundPrimary
        tableView.backgroundColor = .backgroundPrimary
        tableView.separatorColor  = .border
        tableView.separatorInset  = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        setupNavBar()
        setupFields()
        setupUser()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.rightBarButtonItem?.title = nameData.isEmpty ? "button.save".localized() : "button.update".localized()
        self.title = nameData.isEmpty ? "datasecurenote.title.new".localized() : "datasecurenote.title".localized()

        if !nameData.isEmpty {
            titleTextField.text      = nameData
            titleTextField.isEnabled = false
            loadEncryptedDataSecureNote()
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
        saveBtn.tintColor = .accentNotes
        navigationItem.rightBarButtonItem = saveBtn
    }

    private func setupFields() {
        styleTextField(titleTextField, placeholder: "datasecurenote.placeholder.title".localized(), accent: .accentNotes)
        styleTextView(secureNoteTextView)
    }

    private func setupUser() {
        guard let user = Auth.auth().currentUser else {
            SessionManager.resetToSignIn(window: view.window)
            return
        }
        secretKey    = user.uid
        creationDate = Int(user.metadata.creationDate!.timeIntervalSince1970)
    }

    // MARK: — Section headers

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titles = ["datasecurenote.section.title".localized(), "datasecurenote.section.content".localized()]
        guard section < titles.count else { return nil }

        let container = UIView()
        container.backgroundColor = .backgroundPrimary

        let label = UILabel()
        let attributed = NSMutableAttributedString(string: titles[section])
        attributed.addAttribute(.kern,
                                value: 0.8,
                                range: NSRange(location: 0, length: titles[section].count))
        label.attributedText = attributed
        label.font      = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .accentNotes
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

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
        nameData.isEmpty ? saveDataSecureNote() : updateDataSecureNote()
    }

    // MARK: — Data operations

    private func loadEncryptedDataSecureNote() {
        guard let user = Auth.auth().currentUser else {
            SessionManager.resetToSignIn(window: view.window)
            return
        }
        DBManager.shared.getEncryptedDataSecureNote(userID: user.uid, nameData: nameData) { [weak self] data in
            guard let self = self, let data = data else { return }
            let d = self.decryptDataSecureNote(encryptedDataSecureNote: data)
            self.secureNoteTextView.text = d.secureNote
        }
    }

    private func saveDataSecureNote() {
        guard verifyFields(), let encrypted = encryptDataSecureNote() else { return }
        guard let user = Auth.auth().currentUser else {
            SessionManager.resetToSignIn(window: view.window)
            return
        }
        DBManager.shared.saveEncryptedDataSecureNote(
            nameOfData: titleTextField.text!.sanitizeNameForDB(),
            lnkDataSecureNote: encrypted,
            userID: user.uid) { [weak self] success in
            guard let self = self, success else { return }
            self.dismiss(animated: true)
        }
    }

    private func updateDataSecureNote() {
        guard verifyFields(), let encrypted = encryptDataSecureNote() else { return }
        guard let user = Auth.auth().currentUser else {
            SessionManager.resetToSignIn(window: view.window)
            return
        }
        DBManager.shared.updateEncryptedDataSecureNote(
            nameOfData: titleTextField.text!.sanitizeNameForDB(),
            lnkDataSecureNote: encrypted,
            userID: user.uid) { [weak self] success in
            guard let self = self, success else { return }
            self.showAlert(title: "alert.updated.title".localized(), message: "datasecurenote.updated.message".localized()) {
                self.dismiss(animated: true)
            }
        }
    }

    // MARK: — Validation

    private func verifyFields() -> Bool {
        if titleTextField.text?.isEmpty == true {
            showAlert(title: "alert.missing_title.title".localized(), message: "alert.missing_title.note.message".localized())
            return false
        }
        if secureNoteTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showAlert(title: "alert.empty_note.title".localized(), message: "alert.empty_note.message".localized())
            return false
        }
        return true
    }

    // MARK: — Encryption

    private func encryptDataSecureNote() -> LNKDataSecureNote? {
        let e = Encryption.shared.encryptDecrypt
        let p = String(creationDate)
        return LNKDataSecureNote(
            nameData:   e(titleTextField.text!,   p, secretKey, true),
            secureNote: e(secureNoteTextView.text, p, secretKey, true)
        )
    }

    private func decryptDataSecureNote(encryptedDataSecureNote c: LNKDataSecureNote) -> LNKDataSecureNote {
        let d = Encryption.shared.encryptDecrypt
        let p = String(creationDate)
        return LNKDataSecureNote(
            nameData:   d(c.nameData,   p, secretKey, false),
            secureNote: d(c.secureNote, p, secretKey, false)
        )
    }

    // MARK: — Alert helper

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "button.ok".localized(), style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}
