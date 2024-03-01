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
    
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var passwordButton: UIButton!
    
    @IBOutlet weak var requirementsLabel: UILabel!
    
    var setPassword = true
    var temporalPassword = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passwordButton.isEnabled = false
      
        self.hideKeyboardWhenTappedAround()
        passwordText.addTarget(self, action: #selector(MasterPasswordController.textFieldDidChange(_:)), for: .editingChanged)
        passwordText.enablePasswordToggle()
        passwordText.enablePasswordToggle()
        
        if setPassword {
            passwordText.placeholder = "Set Master Password"
            passwordButton.setTitle("Set Password", for: .normal)
        } else {
            passwordText.placeholder = "Type Password"
            passwordButton.setTitle("Unlock", for: .normal)
        }
        
        downloadMasterPassword()
      
    }
    
    override func viewWillAppear(_ animated: Bool) {
       
    }
    
    private func downloadMasterPassword() {
        guard let user = Auth.auth().currentUser else { return }
        
        DBManager.shared.downloadMasterPassword(userID: user.uid) { encryptedPassword in
            print ("Encrypted pass is: \(String(describing: encryptedPassword))")
            if encryptedPassword == nil {
                //Didn't find password, even after creating account
                print ("Failed download master password")
                self.setPassword = true
                DispatchQueue.main.async {
                    self.passwordText.placeholder = "Set Master Password"
                    self.passwordButton.setTitle("Set Password", for: .normal)
                }
            } else {
                print ("FOUND")
                self.setPassword = false
                DispatchQueue.main.async {
                    self.passwordText.placeholder = "Type Password"
                    self.passwordButton.setTitle("Unlock", for: .normal)
                }
            }
        }
    }
    

    @IBAction func passwordButtonTapped(_ sender: Any) {
        
        let cleanPassword = passwordText.text!.cleanPasswordCharacters
        
        guard let user = Auth.auth().currentUser else { return }
        let timeStamp = Int(user.metadata.creationDate!.timeIntervalSince1970)
        UserDefaults.standard.set(timeStamp, forKey: "date_creation_user")
                            
        if setPassword {
            if temporalPassword == "" {
                temporalPassword = cleanPassword
                passwordText.text = ""
                passwordText.placeholder = "Verify Password"
                passwordButton.setTitle("Verify Password", for: .normal)
            } else {
                if cleanPassword == temporalPassword {
                    
                    let encrypted = EncryptionPassword.shared.encryptMasterPassword(encrypting: true, masterPassword: cleanPassword, timeStamp: timeStamp)
                    
                    DBManager.shared.saveMasterPassword(userID: user.uid, encryptedPassword: encrypted) { success in
                        if success {
                            DispatchQueue.main.async {
                                self.dismiss(animated: true)
                            }
                        }
                        print ("Good pass \(cleanPassword)")
                        print ("Encrypted pass \(encrypted)")
                    }
                    
                } else {
                    temporalPassword = ""
                    passwordText.text = ""
                    passwordText.placeholder = "Set Master Password"
                    passwordButton.setTitle("Set Password", for: .normal)
                    let alertController = UIAlertController(title: "Warning", message: "Passwords do not match", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(action)
                    self.present(alertController, animated: true)
                }
            }
        } else {
            DBManager.shared.downloadMasterPassword(userID: user.uid) { encryptedPassword in
                if encryptedPassword != nil {
                    let decrypted = EncryptionPassword.shared.encryptMasterPassword(encrypting: false, masterPassword: encryptedPassword!, timeStamp: timeStamp)
                    
                    if cleanPassword == decrypted {
                        DispatchQueue.main.async {
                            print ("PASS GOOD PASSWORD")
                            self.dismiss(animated: true)
                        }
                    } else {
                        DispatchQueue.main.async {
                            let attempts = UserDefaults.standard.value(forKey: "amount_attempts") as! Int
                            var attempted = UserDefaults.standard.value(forKey: "attempted_failed") as! Int
                            self.passwordText.text = ""
                            
                            if attempted < attempts {
                                attempted += 1
                                UserDefaults.standard.set(attempted, forKey: "attempted_failed")
                                let alertController = UIAlertController(title: "Warning", message: "Wrong password, your information will be erased if you try \((attempts + 1) - attempted) times", preferredStyle: .alert)
                                let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                                alertController.addAction(action)
                                self.present(alertController, animated: true)
                            } else {
                                DBManager.shared.deleteAllDatas(userID: Auth.auth().currentUser!.uid) { success in
                                    if success {
                                        print ("erased")
                                        UserDefaults.standard.set(3, forKey: "amount_attempts")
                                        UserDefaults.standard.set(0, forKey: "attempted_failed")
                                        UserDefaults.standard.set(true, forKey: "locked_app")

                                        self.passwordText.text = ""
                                        exit(0)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        let uppercase = textField.text!.hasCharacter(in: .uppercaseLetters)
        let specialCharacter = textField.text!.hasCharacter(in: .punctuationCharacters)
        let sizePassword = textField.text!.count

        if sizePassword > 8 && specialCharacter && uppercase {
            passwordButton.isEnabled = true
            requirementsLabel.alpha = 0.9
            requirementsLabel.textColor = .blue
        } else {
            requirementsLabel.alpha = 0.5
            requirementsLabel.textColor = .label
            passwordButton.isEnabled = false
        }
    }
}

