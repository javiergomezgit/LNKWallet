//
//  DataSecureNoteController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 7/4/22.
//

import UIKit
import FirebaseAuth

class DataSecureNoteController: UITableViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var secureNoteTextView: UITextView!
    
    public var nameData = ""
    var secretKey = ""
    var creationDate = 0
    
    override func viewWillAppear(_ animated: Bool) {
        if !nameData.isEmpty{
            titleTextField.text = nameData
            titleTextField.isEnabled = false
//            saveButton.setTitle("Update", for: .normal)
            loadEncryptedDataSecureNote()
        } else {
//            saveButton.setTitle("Save", for: .normal)
        }
    }
    
    private func loadEncryptedDataSecureNote() {
        guard let user = Auth.auth().currentUser else {
            SessionManager.resetToSignIn(window: view.window)
            return
        }
        DBManager.shared.getEncryptedDataSecureNote(userID: user.uid, nameData: nameData) { lnkDataSecureNote in
            if lnkDataSecureNote != nil {
                let decryptedData = self.decryptDataSecureNote(encryptedDataSecureNote: lnkDataSecureNote!)
                self.secureNoteTextView.text = decryptedData.secureNote
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        view.backgroundColor = .backgroundPrimary
        tableView.backgroundColor = .backgroundPrimary
        tableView.separatorColor = .clear

        styleFormNavBar(title: nameData.isEmpty ? "New Note" : "Secure Note")
        styleTextField(titleTextField, placeholder: "Note title", accent: .accentNotes)
        styleTextView(secureNoteTextView)
//        stylePrimaryButton(saveButton, title: nameData.isEmpty ? "Save" : "Update", accent: .accentNotes)

        guard let user = Auth.auth().currentUser else {
            SessionManager.resetToSignIn(window: view.window)
            return
        }
        secretKey = user.uid
        if let date = user.metadata.creationDate {
            creationDate = Int(date.timeIntervalSince1970)
        }
        
        // Left — close button
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(exitButtonTapped))
        closeButton.tintColor = .textSecondary
        navigationItem.leftBarButtonItem = closeButton

        // Right — save button
        let saveBtn = UIBarButtonItem(title: nameData.isEmpty ? "Save" : "Update",
                                       style: .done,
                                       target: self,
                                       action: #selector(saveButtonTapped))
        saveBtn.tintColor = .accentNotes
        navigationItem.rightBarButtonItem = saveBtn

        self.title = nameData.isEmpty ? "New Secure Note" : "Secure Note"
    }
    
    @IBAction func exitButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func saveButtonTapped(_ sender: Any) {
        if !nameData.isEmpty {
            updateDataSecureNote()
        } else {
            saveDataSecureNote()
        }
    }
    
    private func saveDataSecureNote() {
        let encryptedData = encryptDataSecureNote()
        guard let user = Auth.auth().currentUser else {
            SessionManager.resetToSignIn(window: view.window)
            return
        }
        if encryptedData != nil {
            DBManager.shared.saveEncryptedDataSecureNote(nameOfData: titleTextField.text!, lnkDataSecureNote: encryptedData!, userID: user.uid) { success in
                if success {
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    private func updateDataSecureNote() {
        let encryptedData = encryptDataSecureNote()
        guard let user = Auth.auth().currentUser else {
            SessionManager.resetToSignIn(window: view.window)
            return
        }
        if encryptedData != nil {
            DBManager.shared.updateEncryptedDataSecureNote(nameOfData: titleTextField.text!, lnkDataSecureNote: encryptedData!, userID: user.uid) { success in
                if success {
                    let alertController = UIAlertController(title: "Updated", message: "Your information has been updated successfully", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default, handler: { _ in
                        self.dismiss(animated: true)
                    })
                    alertController.addAction(action)
                    
                    self.present(alertController, animated: true) {
                        print ("SAVED")
                    }
                }
            }
        }
    }
    
    private func encryptDataSecureNote() -> LNKDataSecureNote? {
        
        let title = Encryption.shared.encryptDecrypt(oldMessage: titleTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let secureNote = Encryption.shared.encryptDecrypt(oldMessage: secureNoteTextView.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        
        
        let encryptedData = LNKDataSecureNote(nameData: title, secureNote: secureNote)
        return encryptedData
    }
    
    private func decryptDataSecureNote(encryptedDataSecureNote: LNKDataSecureNote) -> LNKDataSecureNote {
        
        let title = Encryption.shared.encryptDecrypt(oldMessage: encryptedDataSecureNote.nameData, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let secureNote = Encryption.shared.encryptDecrypt(oldMessage: encryptedDataSecureNote.secureNote, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        
        let decryptedData = LNKDataSecureNote(nameData: title, secureNote: secureNote)
        return decryptedData
    }
}
