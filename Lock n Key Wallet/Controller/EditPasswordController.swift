//
//  EditPasswordController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 12/3/21.
//

import UIKit
import FirebaseAuth

class EditPasswordController: UIViewController {

    private let nameDataText:UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 24, weight: .bold)
        textField.textAlignment = .center
        textField.isEnabled = false
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray5
        textField.placeholder = "Name of your Account".localized()
        return textField
    }()
    public let emailText: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17, weight: .semibold)
        textField.textAlignment = .center
//        textField.isEnabled = false
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.autocapitalizationType = .words
        textField.textContentType = .emailAddress
        textField.keyboardType = .emailAddress
        textField.placeholder = "e-mail"
        return textField
    }()
    public let usernameText: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17, weight: .regular)
//        textField.isEnabled = false
        textField.textAlignment = .center
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.keyboardType = .default
        textField.textContentType = .username
        textField.placeholder = "username (optional)".localized()
        return textField
    }()
    public let passwordText: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17, weight: .regular)
//        textField.isEnabled = false
        textField.textAlignment = .center
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.isSecureTextEntry = true
        textField.enablePasswordToggle()
        textField.backgroundColor = .systemGray6
        textField.placeholder = "Password".localized()

        return textField
    }()
    public let confirmPasswordText: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17, weight: .regular)
//        textField.isEnabled = false
        textField.isHidden = true
        textField.textAlignment = .center
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.keyboardType = .default
        textField.isSecureTextEntry = true
        textField.enablePasswordToggle()
        textField.placeholder = "Verify Password".localized()
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()

        view.addSubview(nameDataText)
        view.addSubview(emailText)
        view.addSubview(usernameText)
        view.addSubview(passwordText)
        view.addSubview(confirmPasswordText)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editData))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let heightView = view.frame.height
        let widthView = view.frame.width
        
        nameDataText.frame = CGRect(
            x: widthView * 0.1, y: heightView * 0.18,
            width: widthView * 0.8,
            height: 60)
        
        emailText.frame = CGRect(
            x: widthView * 0.1,
            y: nameDataText.frame.maxY + 15,
            width: widthView * 0.8,
            height: 50)
       
        usernameText.frame = CGRect(
            x: widthView * 0.1,
            y: emailText.frame.maxY + 15,
            width: widthView * 0.8,
            height: 50)
        
        passwordText.frame = CGRect(
            x: widthView * 0.1,
            y: usernameText.frame.maxY + 15,
            width: widthView * 0.8,
            height: 50)
        
        confirmPasswordText.frame = CGRect(
            x: widthView * 0.1,
            y: passwordText.frame.maxY + 15,
            width: widthView * 0.8,
            height: 50)
    }

    public func configurePass(lockDataPassword: LockDataPassword) {
        if lockDataPassword.email == "N/A" {
            self.emailText.text = ""
        } else {
            self.emailText.text = lockDataPassword.email
        }
        if lockDataPassword.username == "N/A" {
            self.usernameText.text = ""
        } else {
            self.usernameText.text = lockDataPassword.username
        }
        self.nameDataText.text = lockDataPassword.nameData
        self.passwordText.text = lockDataPassword.password
    }
    
    private var editingInfo = false
}


//MARK: Edit functions
extension EditPasswordController {
    
    @objc func editData() {
                
        if editingInfo == true {
            editingInfo = false
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editData))
            saveData()
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(editData))
            editingInfo = true
            //        emailText.isEnabled = true
            //        usernameText.isEnabled = true
            //        passwordText.isEnabled = true
            //        confirmPasswordText.isEnabled = true
                    confirmPasswordText.isHidden = false
        }
    }
    
    @objc func saveData() {
        if verifyEmptyField() {
            let passToSave = LockDataPassword(nameData: nameDataText.text!, username: usernameText.text!, email: emailText.text!, password: passwordText.text!)
            let encryptedData = encryptData(encrypt: true, lockDataPass: passToSave)

            DBManager.shared.saveEncryptedDataPasswords(nameOfDataPassword: nameDataText.text!, contentDataPassword: encryptedData!.contentData, user: encryptedData!.userData!, userID: Auth.auth().currentUser!.uid) { success in
                if success {
//                    self.nameDataText.isEnabled = false
//                    self.emailText.isEnabled = false
//                    self.usernameText.isEnabled = false
//                    self.confirmPasswordText.isEnabled = false
//                    self.passwordText.isEnabled = false
                    
                    let alertController = UIAlertController(title: "Saved".localized(), message: "Your information has been saved successfully".localized(), preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(action)
                    self.present(alertController, animated: true) { [self] in
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(saveData))
                    }
                }
            }
            print ("can save")
        }
    }
    
    private func encryptData(encrypt: Bool, lockDataPass: LockDataPassword) -> LNKData? {
        let userData = "\(lockDataPass.username!) \(lockDataPass.email!)"
        let passData = lockDataPass.password
        
        let passcode = UserDefaults.standard.value(forKey: "general_passcode") as! String
        guard let secretKey = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        let encryptedUserData = Encryption.shared.encryptDecrypt(oldMessage: userData, encryptedPasscode: passcode, secretKey: secretKey, encrypt: true)
        let encryptedContentData = Encryption.shared.encryptDecrypt(oldMessage: passData, encryptedPasscode: passcode, secretKey: secretKey, encrypt: true)
        
        let encryptedData = LNKData(nameData: lockDataPass.nameData, userData: encryptedUserData, contentData: encryptedContentData)
        return encryptedData
    }
    
    private func verifyEmptyField() -> Bool {
        var verify = false
        if emailText.text == "" ||
            confirmPasswordText.text == "" ||
            passwordText.text == "" {
            verify = false
            let alertController = UIAlertController(title: "Empty Fields".localized(), message: "You are trying to save empty fields".localized(), preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        } else if passwordText.text != confirmPasswordText.text {
            verify = false
            let alertController = UIAlertController(title: "Password not matching".localized(), message: "The verification of your password is not matching".localized(), preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        } else {
            verify = true
        }
        return verify
    }
}
