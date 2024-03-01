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
    @IBOutlet weak var saveButton: UIButton!
    
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
        
        if user  != nil {
            secretKey = user!.uid
            creationDate = Int(user!.metadata.creationDate!.timeIntervalSince1970)
        } else {
            print("NO user signed in")
            exit(0)
        }
        
        configureTops()
    }
    
    private func configureTops() {
        title = "Save Data"
//        let rightButtonImage = UIImage(systemName: "icloud.and.arrow.up.fill")?.withRenderingMode(.alwaysTemplate)
        if !nameData.isEmpty {
            saveButton.setTitle("Update", for: .normal)
//            let rightButton = UIBarButtonItem(image: rightButtonImage, style: .plain, target: self, action: #selector(updateDataPassword))
//            self.navigationItem.rightBarButtonItem = rightButton
        } else {
            saveButton.setTitle("Save", for: .normal)
//            let rightButton = UIBarButtonItem(image: rightButtonImage, style: .plain, target: self, action: #selector(saveDataPassword))
//            self.navigationItem.rightBarButtonItem = rightButton
        }
//
//        if traitCollection.userInterfaceStyle == .light {
//            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "darkblueAccent")!
//        } else {
//            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "mainOrange")!
//        }
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
        if verifyPassFields() {
            let encryptedData = encryptDataPassword()
            if encryptedData != nil {
                DBManager.shared.saveEncryptedDataPassword(nameOfData: titleTextField.text!, lnkDataPassword: encryptedData!, userID: Auth.auth().currentUser!.uid) { success in
                    if success {
                        self.dismiss(animated: true)
                        
//                        let alertController = UIAlertController(title: "Saved", message: "Your information has been saved successfully", preferredStyle: .alert)
//                        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
//                        alertController.addAction(action)
//                        self.present(alertController, animated: true) { [self] in
//                            self.titleTextField.text = ""
//                            self.emailTextField.text = ""
//                            self.otherTextField.text = ""
//                            self.passwordTextField.text = ""
//                            self.websiteTextField.text = ""
//                        }
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
//                            self.navigationController?.popToRootViewController(animated: true)
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
