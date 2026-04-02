//
//  DataPasswordController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 7/2/22.
//

import UIKit
import FirebaseAuth

class DataPasswordController: UITableViewController {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var otherTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var websiteTextField: UITextField!
//    @IBOutlet weak var saveButton: UIButton!
    
    public var nameData = ""
    var secretKey = ""
    var creationDate = 0
    var user = Auth.auth().currentUser
    
    override func viewWillAppear(_ animated: Bool) {
        if !nameData.isEmpty{
            titleTextField.text = nameData
            titleTextField.isEnabled = false
            loadEncryptedDataPassword()
        }
    }
    
    private func loadEncryptedDataPassword() {
        
        DBManager.shared.getEncryptedDataPassword(userID: user!.uid, nameData: nameData) { lnkDataPassword in
            if lnkDataPassword != nil {
                let decryptedData = self.decryptDataPassword(encryptedDataPassword: lnkDataPassword!)
                self.emailTextField.text = decryptedData.email
                self.otherTextField.text = decryptedData.username
                self.passwordTextField.text = decryptedData.password
                self.websiteTextField.text = decryptedData.website
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        passwordTextField.enablePasswordToggle()
        view.backgroundColor = .backgroundPrimary
        tableView.backgroundColor = .backgroundPrimary
        tableView.separatorColor = .clear

        styleFormNavBar(title: nameData.isEmpty ? "New Password" : "Password")
        styleTextField(titleTextField, placeholder: "Name (e.g. Gmail)")
        styleTextField(emailTextField, placeholder: "Email or username")
        styleTextField(otherTextField, placeholder: "Other (optional)")
        styleTextField(passwordTextField, placeholder: "Password")
        styleTextField(websiteTextField, placeholder: "Website")
//        stylePrimaryButton(saveButton, title: nameData.isEmpty ? "Save" : "Update", accent: .accentBrand)

        if user != nil {
            secretKey = user!.uid
            creationDate = Int(user!.metadata.creationDate!.timeIntervalSince1970)
        } else {
            exit(0)
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
        saveBtn.tintColor = .accentBrand
        navigationItem.rightBarButtonItem = saveBtn

        self.title = nameData.isEmpty ? "New Password" : "Password"
    }
    
//    private func configureTops() {
//        title = "Save Data"
//        if !nameData.isEmpty {
//            saveButton.setTitle("Update", for: .normal)
//
//        } else {
//            saveButton.setTitle("Save", for: .normal)
//
//        }
//    }
    
    @IBAction func exitButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func saveButtonTapped(_ sender: Any) {
        if !nameData.isEmpty {
            updateDataPassword()
        } else {
            saveDataPassword()
        }
    }
    
    private func saveDataPassword() {
        if verifyPassFields() {
            let encryptedData = encryptDataPassword()
            if encryptedData != nil {
                DBManager.shared.saveEncryptedDataPassword(nameOfData: titleTextField.text!, lnkDataPassword: encryptedData!, userID: Auth.auth().currentUser!.uid) { success in
                    if success {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    private func updateDataPassword() {
        if verifyPassFields() {
            let encryptedData = encryptDataPassword()
            if encryptedData != nil {
                DBManager.shared.updateEncryptedDataPassword(nameOfData: titleTextField.text!, lnkDataPassword: encryptedData!, userID: Auth.auth().currentUser!.uid) { success in
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
    }
    
    private func verifyPassFields() -> Bool {
        var verify = false
        
        if titleTextField.text == "" {
            verify = false
            let alertController = UIAlertController(title: "Empty Fields", message: "Please make sure to give a name to this account", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        } else if passwordTextField.text == "" {
            verify = false
            let alertController = UIAlertController(title: "Wrong Password", message: "Password can not be empty", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        } else {
            verify = true
        }
        return verify
    }
    
    private func encryptDataPassword() -> LNKDataPassword? {
        
        let title = Encryption.shared.encryptDecrypt(oldMessage: titleTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let email = Encryption.shared.encryptDecrypt(oldMessage: emailTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let other = Encryption.shared.encryptDecrypt(oldMessage: otherTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let password = Encryption.shared.encryptDecrypt(oldMessage: passwordTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let website = Encryption.shared.encryptDecrypt(oldMessage: websiteTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        
        let encryptedData = LNKDataPassword(nameData: title, email: email, username: other, password: password, website: website)
        return encryptedData
    }
    
    private func decryptDataPassword(encryptedDataPassword: LNKDataPassword) -> LNKDataPassword {
        
        let title = Encryption.shared.encryptDecrypt(oldMessage: encryptedDataPassword.nameData, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let email = Encryption.shared.encryptDecrypt(oldMessage: encryptedDataPassword.email, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let other = Encryption.shared.encryptDecrypt(oldMessage: encryptedDataPassword.username, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let password = Encryption.shared.encryptDecrypt(oldMessage: encryptedDataPassword.password, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let website = Encryption.shared.encryptDecrypt(oldMessage: encryptedDataPassword.website, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        
        let decryptedData = LNKDataPassword(nameData: title, email: email, username: other, password: password, website: website)
        return decryptedData
    }
}
