//
//  EditDataController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/27/21.
//

import UIKit
import FirebaseAuth

class EditDataController: UIViewController {
    
    private let nameDataText:UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 24, weight: .bold)
        textField.textAlignment = .center
        textField.isEnabled = false
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray5
        textField.placeholder = "Name of your Bank".localized()
        return textField
    }()
    public let nameONCardText: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17, weight: .semibold)
        textField.textAlignment = .center
        textField.isEnabled = false
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.autocapitalizationType = .words
        textField.textContentType = .name
        textField.placeholder = "Name on the credit card".localized()
        return textField
    }()
    public let noCardText: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17, weight: .regular)
        textField.isEnabled = false
        textField.textAlignment = .center
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.keyboardType = .numberPad
        textField.textContentType = .creditCardNumber
        textField.placeholder = "No. on the card".localized()
        return textField
    }()
    public let copyNoCardButton: UIButton = {
        let button = UIButton()
        //button.setTitle("Copy", for: .normal)
        button.setTitleColor(UIColor.label, for: .normal)
        button.contentHorizontalAlignment = .right
        button.backgroundColor = .cyan.withAlphaComponent(0.1)
        button.isHidden = false
        
        
        let icon = UIImage(systemName: "doc.on.doc")!
        button.setImage(icon, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)

        button.addTarget(self, action: #selector(copyText), for: .touchUpInside)
        return button
    }()
    public let expirationText: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17, weight: .regular)
        textField.isEnabled = false
        textField.textAlignment = .center
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.backgroundColor = .systemGray6
        textField.placeholder = "12/21"
        textField.addTarget(self, action: #selector(cleanLabelDate), for: .editingChanged)
        textField.addTarget(self, action: #selector(cleanDate), for: .editingDidEnd)
        return textField
    }()
    public let expirationLabel: UILabel = {
       let label = UILabel()
        label.text = "01/21"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textAlignment = .center
        return label
    }()
    public let securityCodeText: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17, weight: .regular)
        textField.isEnabled = false
        textField.textAlignment = .center
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.keyboardType = .numberPad
        textField.placeholder = "CCV"
        return textField
    }()
    
    private var editingInfo = false
    private var expirationDate = ""
    private let monthNames = ["Jan".localized(), "Feb".localized(), "Mar".localized(), "Apr".localized(), "May".localized(), "Jun".localized(), "Jul".localized(), "Aug".localized(), "Sept".localized(), "Oct".localized(), "Nov".localized(), "Dec".localized()]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        view.addSubview(nameDataText)
        view.addSubview(nameONCardText)
        view.addSubview(noCardText)
        view.addSubview(copyNoCardButton)
        view.addSubview(expirationText)
        view.addSubview(securityCodeText)
        view.addSubview(expirationLabel)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editData))
    }
    
    @objc func copyText(sender : UIButton){
        if noCardText.text != nil {
            UIPasteboard.general.string = noCardText.text
            let alert = UIAlertController(title: "Copied", message: "Your number has been copied", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                print("Number copied")
            }
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion:nil)
        }
    }
    
    @objc func editData() {
        
        if editingInfo == true {
            editingInfo = false
            copyNoCardButton.isHidden = false
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editData))
            saveData()
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(editData))
            editingInfo = true
            copyNoCardButton.isHidden = true
            nameONCardText.isEnabled = true
            noCardText.isEnabled = true
            expirationText.isEnabled = true
            securityCodeText.isEnabled = true
        }
    }
    
    @objc func saveData() {
        
        if verifyEmptyField() {
            let dataToSave = LockData(nameData: nameDataText.text!, nameOnCard: nameONCardText.text!, numberCard: noCardText.text!, expDate: expirationText.text!, securityCode: securityCodeText.text!)
            let encryptedData = encryptData(encrypt: true, lockData: dataToSave)
            
            DBManager.shared.saveEncryptedData(nameOfData: nameDataText.text!, contentData: encryptedData, userID: Auth.auth().currentUser!.uid) { success in
                if success {
                    self.nameDataText.isEnabled = false
                    self.nameONCardText.isEnabled = false
                    self.noCardText.isEnabled = false
                    self.copyNoCardButton.isHidden = false
                    self.securityCodeText.isEnabled = false
                    self.expirationText.isEnabled = false
                    
                    let alertController = UIAlertController(title: "Saved".localized(), message: "Your information has been saved successfully".localized(), preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(action)
                    self.present(alertController, animated: true) { [self] in
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editData))
                    }
                }
            }
            print ("can save")
        }
    }

    @objc private func cleanLabelDate() {
        if expirationText.text!.count <= 2 || expirationText.text!.count > 4 || expirationText.text!.isEmpty {
            expirationLabel.text = ""
        } else {
            cleanDate()
        }
    }

    @objc private func cleanDate() {
        let dateText = expirationText.text!
        if dateText.count > 2 && dateText.count < 5 {
            var string1 = ""
            var string2 = ""
            if dateText.count == 3 {
                for (i, char) in dateText.enumerated() {
                    if i < 1 {
                        print (char)
                        string1 += String(char)
                    } else {
                        string2 += String(char)
                    }
                }
            } else {
                for (i, char) in dateText.enumerated() {
                    if i < 2 {
                        print (char)
                        string1 += String(char)
                    } else {
                        string2 += String(char)
                    }
                }
            }
            
            let monthNumber = Int(string1)
            let yearNumber = Int(string2)
            if monthNumber! >= 1 && monthNumber! <= 12 {
                if yearNumber! >= 20 && yearNumber! <= 35 {
                    expirationLabel.text = "\(monthNames[monthNumber!-1]) / 20\(string2)"
                } else {
                    expirationLabel.text = ""
                }
            } else {
                expirationLabel.text = ""
            }
        } else {
            expirationLabel.text = ""
        }
    }
    
    private func encryptData(encrypt: Bool, lockData: LockData) -> String {
        var composeData = "\(lockData.securityCode)*\(lockData.expDate)*\(lockData.numberCard)*\(lockData.nameOnCard)"
        let passcode = UserDefaults.standard.value(forKey: "general_passcode") as! String
        guard let secretKey = Auth.auth().currentUser?.uid else {
            composeData.removeAll()
            return composeData
        }
        
        let encryptedData = Encryption.shared.encryptDecrypt(oldMessage: composeData, encryptedPasscode: passcode, secretKey: secretKey, encrypt: true)
        return encryptedData
    }
    
    private func verifyEmptyField() -> Bool {
        var verify = false
        if nameONCardText.text == "" ||
            noCardText.text == "" ||
            securityCodeText.text == "" ||
            expirationText.text == "" ||
            expirationLabel.text == "" {
            verify = false
            let alertController = UIAlertController(title: "Empty Fields".localized(), message: "You are trying to save empty fields".localized(), preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        } else {
            verify = true
        }
        return verify
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let heightView = view.frame.height
        let widthView = view.frame.width
        
        nameDataText.frame = CGRect(
            x: widthView * 0.1, y: heightView * 0.18,
            width: widthView * 0.8,
            height: 60)
        
        nameONCardText.frame = CGRect(
            x: widthView * 0.1,
            y: nameDataText.frame.maxY + 15,
            width: widthView * 0.8,
            height: 50)
        
        noCardText.frame = CGRect(
            x: widthView * 0.1,
            y: nameONCardText.frame.maxY + 15,
            width: widthView * 0.8,
            height: 50)
        
        copyNoCardButton.frame = CGRect(
            x: widthView * 0.1,
            y: nameONCardText.frame.maxY + 15,
            width: widthView * 0.8,
            height: 50)
        
        expirationText.frame = CGRect(
            x: widthView * 0.1,
            y: noCardText.frame.maxY + 15,
            width: widthView * 0.38,
            height: 50)
        
        expirationLabel.frame = CGRect(
            x: widthView * 0.1,
            y: expirationText.frame.maxY + 3,
            width: widthView * 0.38,
            height: 25)
        
        securityCodeText.frame = CGRect(
            x: widthView * 0.52,
            y: noCardText.frame.maxY + 15,
            width: widthView * 0.38,
            height: 50)
    }
    
    public func configure(lockData: LockData) {
        self.nameDataText.text = lockData.nameData
        self.nameONCardText.text = lockData.nameOnCard
        self.noCardText.text = lockData.numberCard
        self.expirationText.text = lockData.expDate
        self.securityCodeText.text = lockData.securityCode
        cleanDate()
    }
    
    public func configurePass(lockPass: LockDataPassword) {
        print (lockPass)
    }
}
