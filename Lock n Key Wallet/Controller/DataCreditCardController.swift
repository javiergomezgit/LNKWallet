//
//  DataCreditCardController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 7/2/22.
//

import UIKit
import FirebaseAuth
import CreditCardScanner

class DataCreditCardController: UITableViewController {

    @IBOutlet weak var accountNameTextField: UITextField!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cardholderNameTextField: UITextField!
    @IBOutlet weak var cardNumberTextField: UITextField!
    @IBOutlet weak var ccvTextField: UITextField!
    @IBOutlet weak var zipCodeTextField: UITextField!
    @IBOutlet weak var expirationButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    
    let pickerView = UIPickerView()
    let monthPickerData = [String](arrayLiteral: "January - 1", "February - 2", "March - 3", "April - 4",
                                                 "May - 5", "June - 6", "July - 7", "August - 8", "September - 9",
                                                 "October - 10", "November - 11", "December - 12")
    
    let yearPickerData = [String](arrayLiteral: "2022", "2023", "2024", "2025", "2026", "2027", "2028", "2029", "2030", "2031", "2032", "2033","2034", "2035", "2036", "2037")
    let yearNumbers = [22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37]
    
    public var nameData = ""
    var secretKey = ""
    var creationDate = 0
    var user = Auth.auth().currentUser
    
    @IBAction func exitButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !nameData.isEmpty{
            accountNameTextField.text = nameData
            accountNameTextField.isEnabled = false
            loadEncryptedDataCreditCard()
        }
    }
    
    private func loadEncryptedDataCreditCard() {
        DBManager.shared.getEncryptedDataCreditCard(userID: user!.uid, nameData: nameData) { lnkDataCreditCard in
            if lnkDataCreditCard != nil {
                let decryptedData = self.decryptDataCreditCard(lnkDataCreditCard: lnkDataCreditCard!)
                self.cardholderNameTextField.text = decryptedData.nameOnCard
                self.cardNumberTextField.text = decryptedData.numberCard
                self.ccvTextField.text = decryptedData.securityCode
                self.zipCodeTextField.text = decryptedData.zipCode
                self.expirationButton.setTitle(decryptedData.expDate, for: .normal)
                self.expirationButton.setTitleColor(.label, for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hideKeyboardWhenTappedAround()
        configureTops()
        expirationButton.cornersView(border: true, roundedCorner: 10)
        
        if user  != nil {
            secretKey = user!.uid
            creationDate = Int(user!.metadata.creationDate!.timeIntervalSince1970)
        } else {
            print("NO user signed in")
            exit(0)
        }
        
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width - 20.0, height: 200)
    }
    
    private func configureTops() {
        title = "Credit Card"
        if !nameData.isEmpty {
            saveButton.setTitle("Update", for: .normal)
        } else {
            saveButton.setTitle("Save", for: .normal)
        }
//        if traitCollection.userInterfaceStyle == .light {
//            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "darkblueAccent")!
//        } else {
//            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "mainOrange")!
//        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        if !nameData.isEmpty {
            updateData()
        } else {
            saveData()
        }
    }
    
    
    private func saveData() {
    
        if verifyEmptyField() {
           
            let encryptedData =  encryptDataCreditCard()
            
            if encryptedData != nil {
                DBManager.shared.saveEncryptedCreditCard(nameOfData: accountNameTextField.text!, lnkDataCreditCard: encryptedData!, userID: Auth.auth().currentUser!.uid) { success in
                    if success {
                        let alertController = UIAlertController(title: "Saved", message: "Your information has been saved successfully", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alertController.addAction(action)
                        self.present(alertController, animated: true) { [self] in
                            self.accountNameTextField.text = ""
                            self.cardholderNameTextField.text = ""
                            self.cardNumberTextField.text = ""
                            self.zipCodeTextField.text = ""
                            self.ccvTextField.text = ""
                            self.expirationButton.setTitle("MM/YY", for: .normal)
                            self.expirationButton.setTitleColor(.gray, for: .normal)
                        }
                    }
                }
            }
        }
    }
    
    private func updateData() {
    
        if verifyEmptyField() {
           
            let encryptedData =  encryptDataCreditCard()
            
            if encryptedData != nil {
                DBManager.shared.updateEncryptedCreditCard(nameOfData: accountNameTextField.text!, lnkDataCreditCard: encryptedData!, userID: Auth.auth().currentUser!.uid) { success in
                    if success {
                        let alertController = UIAlertController(title: "Updated", message: "Your information has been updated successfully", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .default, handler: { _ in
                            self.dismiss(animated: true)
//                            self.navigationController?.popToRootViewController(animated: true)
                        })
                        alertController.addAction(action)
                        self.present(alertController, animated: true) {
                            print ("Saved Information")
                        }
                    }
                }
            }
        }
    }
    
    private func encryptDataCreditCard() -> LNKDataCreditCard? {
        
        let accName = Encryption.shared.encryptDecrypt(oldMessage: accountNameTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let name = Encryption.shared.encryptDecrypt(oldMessage: cardholderNameTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let number = Encryption.shared.encryptDecrypt(oldMessage: cardNumberTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let ccv = Encryption.shared.encryptDecrypt(oldMessage: ccvTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let zip = Encryption.shared.encryptDecrypt(oldMessage: zipCodeTextField.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        let exp = Encryption.shared.encryptDecrypt(oldMessage: expirationButton.titleLabel!.text!, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: true)
        
        let encryptedData = LNKDataCreditCard(nameData: accName, nameOnCard: name, numberCard: number, securityCode: ccv, zipCode: zip, expDate: exp)
        return encryptedData
    }
    
    private func decryptDataCreditCard(lnkDataCreditCard: LNKDataCreditCard) -> LNKDataCreditCard {
        
        let accName = Encryption.shared.encryptDecrypt(oldMessage: lnkDataCreditCard.nameData, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let name = Encryption.shared.encryptDecrypt(oldMessage: lnkDataCreditCard.nameOnCard, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let number = Encryption.shared.encryptDecrypt(oldMessage: lnkDataCreditCard.numberCard, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let ccv = Encryption.shared.encryptDecrypt(oldMessage: lnkDataCreditCard.securityCode, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let zip = Encryption.shared.encryptDecrypt(oldMessage: lnkDataCreditCard.zipCode, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        let exp = Encryption.shared.encryptDecrypt(oldMessage: lnkDataCreditCard.expDate, encryptedPasscode: String(creationDate), secretKey: secretKey, encrypt: false)
        
        let decryptedData = LNKDataCreditCard(nameData: accName, nameOnCard: name, numberCard: number, securityCode: ccv, zipCode: zip, expDate: exp)
        return decryptedData
    }
    
    
    
    private func verifyEmptyField() -> Bool {
        var verify = false
        if accountNameTextField.text == "" ||
            cardholderNameTextField.text == "" ||
            cardNumberTextField.text == "" ||
            ccvTextField.text == "" ||
            expirationButton.titleLabel?.text == "" {
            
            verify = false
            let alertController = UIAlertController(title: "Empty Fields", message: "You are trying to save empty information", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        } else {
            verify = true
        }
        return verify
    }
    
    @IBAction func cameraScannerTapped(_ sender: UIButton) {
        
        let vc = CreditCardScannerViewController(delegate: self)
        vc.titleLabelText = "Place card"
        vc.subtitleLabelText = "Line up card within the lines"
        vc.labelTextColor = .white
        vc.cancelButtonTitleText = "Cancel"
        vc.cancelButtonTitleTextColor = UIColor(named: "mainOrange")!
        vc.cameraViewCreditCardFrameStrokeColor = .white
        vc.cameraViewMaskLayerColor = .black
        vc.cameraViewMaskAlpha = 0.7
        vc.textBackgroundColor = .black
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
        
        
    }
    
    @IBAction func expirationButtonTapped(_ sender: UIButton) {
        
        let alertController = UIAlertController(title: "Expiration Date", message: "", preferredStyle: .actionSheet)
        alertController.isModalInPresentation = false
        alertController.view.addSubview(pickerView)
        
        let height:NSLayoutConstraint = NSLayoutConstraint(item: alertController.view!,
                                                           attribute: NSLayoutConstraint.Attribute.height,
                                                           relatedBy: NSLayoutConstraint.Relation.equal,
                                                           toItem: nil,
                                                           attribute: NSLayoutConstraint.Attribute.notAnAttribute,
                                                           multiplier: 1, constant: self.view.frame.height / 3)
        alertController.view.addConstraint(height)
        
        let selectedDateAction = UIAlertAction(title: "Select Date", style: .default) { alert in
            let selectedMonth = self.pickerView.selectedRow(inComponent: 0)
            let selectedYear = self.yearNumbers[self.pickerView.selectedRow(inComponent: 1)]
            let selectedDate = "\(selectedMonth + 1) / \(selectedYear)"
            
            self.expirationButton.setTitle(selectedDate, for: .normal)
            self.expirationButton.setTitleColor(.label, for: .normal)
        }
        
        alertController.addAction(selectedDateAction)
        self.present(alertController, animated: true, completion: nil)
    }
}


extension DataCreditCardController: UIPickerViewDelegate, UIPickerViewDataSource {
  
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return monthPickerData.count
        } else {
            return yearPickerData.count
        }
    }

    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return monthPickerData[row]
        } else {
            return yearPickerData[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 46.0
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return self.view.frame.size.width / 2.5
    }
}


extension DataCreditCardController: CreditCardScannerViewControllerDelegate {
    func creditCardScannerViewControllerDidCancel(_ viewController: CreditCardScannerViewController) {
        viewController.dismiss(animated: true, completion: nil)
        print("cancel")
    }
    
    func creditCardScannerViewController(_ viewController: CreditCardScannerViewController, didErrorWith error: CreditCardScannerError) {
        print(error.errorDescription ?? "")
        //        resultLabel.text = error.errorDescription
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func creditCardScannerViewController(_ viewController: CreditCardScannerViewController, didFinishWith card: CreditCard) {
        viewController.dismiss(animated: true, completion: nil)
        
        var dateComponents = card.expireDate
        dateComponents?.calendar = Calendar.current
        let dateFormater = DateFormatter()
        dateFormater.dateStyle = .short
        let date = dateComponents?.date.flatMap(dateFormater.string)
        
        let text = [card.number, date, card.name]
            .compactMap { $0 }
            .joined(separator: "\n")
        print (text)
        
        if let number = card.number {
            cardNumberTextField.text = number
        }
        
        if let name = card.name {
            cardholderNameTextField.text = name
        }
        
        if var yearDate = card.expireDate?.year, let monthDate = card.expireDate?.month {
            yearDate = yearDate - 2000
            let expDate = "\(monthDate) / \(yearDate)"
            expirationButton.setTitle(expDate, for: .normal)
            expirationButton.setTitleColor(.label, for: .normal)
        }
    }
}
