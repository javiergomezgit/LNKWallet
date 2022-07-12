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
    @IBOutlet weak var saveButton: UIButton!
    
    public var nameData = ""
    var secretKey = ""
    var creationDate = 0
    var user = Auth.auth().currentUser
    
    override func viewWillAppear(_ animated: Bool) {
        if !nameData.isEmpty{
            titleTextField.text = nameData
            titleTextField.isEnabled = false
            saveButton.setTitle("Update", for: .normal)
            loadEncryptedDataSecureNote()
        } else {
            saveButton.setTitle("Save", for: .normal)
        }
    }
    
    private func loadEncryptedDataSecureNote() {
        
        DBManager.shared.getEncryptedDataSecureNote(userID: user!.uid, nameData: nameData) { lnkDataSecureNote in
            if lnkDataSecureNote != nil {
                let decryptedData = self.decryptDataSecureNote(encryptedDataSecureNote: lnkDataSecureNote!)
                self.secureNoteTextView.text = decryptedData.secureNote
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        if user  != nil {
            secretKey = user!.uid
            creationDate = Int(user!.metadata.creationDate!.timeIntervalSince1970)
        } else {
            print("NO user signed in")
            exit(0)
        }
        
        //secureNoteTextView.cornersView(border: true, roundedCorner: 10)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        if !nameData.isEmpty {
            updateDataPassword()
        } else {
            saveDataPassword()
        }
    }
    
    @IBAction func exitButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    private func saveDataPassword() {
        let encryptedData = encryptDataSecureNote()
        if encryptedData != nil {
            DBManager.shared.saveEncryptedDataSecureNote(nameOfData: titleTextField.text!, lnkDataSecureNote: encryptedData!, userID: user!.uid) { success in
                if success {
                    self.dismiss(animated: true)
//                    let alertController = UIAlertController(title: "Saved", message: "Your information has been saved successfully", preferredStyle: .alert)
//                    let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
//                    alertController.addAction(action)
//                    self.present(alertController, animated: true) { [self] in
//                        self.titleTextField.text = ""
//                        self.secureNoteTextView.text = ""
//                    }
                }
            }
        }
    }
    
    private func updateDataPassword() {
        let encryptedData = encryptDataSecureNote()
        if encryptedData != nil {
            DBManager.shared.updateEncryptedDataSecureNote(nameOfData: titleTextField.text!, lnkDataSecureNote: encryptedData!, userID: user!.uid) { success in
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
