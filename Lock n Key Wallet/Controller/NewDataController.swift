//
//  EntryController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/19/21.
//

import UIKit
import FirebaseAuth
import CreditCardScanner

class NewDataController: UIViewController {
    
    @IBOutlet weak var dataSelector: UISegmentedControl!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var creditCardView: UIView!
    
    @IBOutlet weak var nameDataText: UITextField!
    @IBOutlet weak var nameOnCardText: UITextField!
    @IBOutlet weak var numberCardText: UITextField!
    @IBOutlet weak var securityCodeText: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    
    var monthNames: [Int: String] = [Int: String]()
    var expirationDate: String?
    
    @IBOutlet weak var verifyPassText: UITextField!
    @IBOutlet weak var passPassText: UITextField!
    @IBOutlet weak var usernamePassText: UITextField!
    @IBOutlet weak var emailPassText: UITextField!
    @IBOutlet weak var nameDataPassText: UITextField!
    @IBOutlet weak var yearText: UITextField!
    @IBOutlet weak var monthText: UITextField!
    
    public var typeOfData = ""
    
    @IBAction func changed(_ sender: Any) {
        
        //TODO: Sepearate number every 4 characteres
        //        var textInField = numberCardText.text!
        //        textInField = textInField.replacingOccurrences(of: " ", with: "")
        //
        //        if numberCardText.text!.count == 4 {
        //            let textAdded = "\(numberCardText.text!) "
        //            numberCardText.text! = textAdded
        //        }
        //        if numberCardText.text!.count == 9 {
        //            let textAdded = "\(numberCardText.text!) "
        //            numberCardText.text! = textAdded
        //        }
    }
    
    @IBAction func monthTextChanged(_ sender: UITextField) {
        var monthValue = Int(monthText.text!) ?? 1
        var monthName = ""
        if monthValue >= 1 && monthValue <= 12 {
            monthName = monthNames[monthValue]!
        } else {
            monthValue = 1
            monthName = monthNames[monthValue]!
        }
        
        var yearValue = Int(yearText.text!) ?? 23
        var yearName = ""
        if yearValue >= 22 && monthValue <= 30 {
            yearName = "20\(yearValue)"
        } else {
            yearValue = 23
            yearName = "20\(yearValue)"
        }
        
        monthText.text = String(monthValue)
        yearText.text = String(yearValue)
        let dateName = "\(monthName) / \(yearName)"
        dateLabel.text = dateName
        expirationDate = "\(monthValue)/\(yearName)"
        
    }
    
    @IBAction func yearTextChanged(_ sender: UITextField) {
        var monthValue = Int(monthText.text!) ?? 1
        var monthName = ""
        if monthValue >= 1 && monthValue <= 12 {
            monthName = monthNames[monthValue]!
        } else {
            monthValue = 1
            monthName = monthNames[monthValue]!
        }
        
        var yearValue = Int(yearText.text!) ?? 23
        var yearName = ""
        if yearValue >= 22 && yearValue <= 30 {
            yearName = "20\(yearValue)"
        } else {
            yearValue = 23
            yearName = "20\(yearValue)"
        }
        
        monthText.text = String(monthValue)
        yearText.text = String(yearValue)
        let dateName = "\(monthName) / \(yearName)"
        dateLabel.text = dateName
        expirationDate = "\(monthValue)/\(yearName)"
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch typeOfData {
        case "credit_card":
            dataSelector.selectedSegmentIndex = 0
        case "password" :
            dataSelector.selectedSegmentIndex = 1
        default:
            print ("selected secure note")
        }
        
        self.hideKeyboardWhenTappedAround()
        passPassText.enablePasswordToggle()
        verifyPassText.enablePasswordToggle()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(configureSecurity), name: UIApplication.willResignActiveNotification, object: nil)
        
        configureTops()
        configureSecurity()
        
        monthNames = [
            1: "Jan".localized(),
            2: "Feb".localized(),
            3: "Mar".localized(),
            4: "Apr".localized(),
            5: "May".localized(),
            6: "Jun".localized(),
            7: "Jul".localized(),
            8: "Aug".localized(),
            9: "Sept".localized(),
            10: "Oct".localized(),
            11: "Nov".localized(),
            12: "Dec".localized()
        ]
        
    }
    
    @objc private func configureSecurity() {
        //        if (UserDefaults.standard.value(forKey: "found_passcode") as! Bool) == false {
        //            UserDefaults.standard.set(true, forKey: "is_new_user")
        //        }
        
        if (UserDefaults.standard.value(forKey: "is_new_user") as! Bool) == true {
            print ("NEW USER")
            UserDefaults.standard.set(false, forKey: "is_new_user")
            //            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            //            let vc = storyboard.instantiateViewController(identifier: "PasscodeController") as! PasscodeController
            //            vc.statusOfPasscode = .settingPasscode
            //            vc.modalPresentationStyle = .fullScreen
            //            vc.completion = { success in
            //                if success {
            //                    print ("Set up passcode")
            //                    UserDefaults.standard.set(0, forKey: "attemptedPasscode")
            //                    UserDefaults.standard.set(3, forKey: "amount_attempts")
            //                } else {
            //                    print ("no success")
            //                }
            //            }
            //            self.present(vc, animated: true)
        } else {
            print ("NO NEW")
            var attempted = UserDefaults.standard.value(forKey: "attemptedPasscode") as? Int
            var amountAttempts = UserDefaults.standard.value(forKey: "amount_attempts") as? Int
            
            if attempted == nil {
                UserDefaults.standard.set(0, forKey: "attemptedPasscode")
                attempted = 0
            }
            if amountAttempts == nil {
                UserDefaults.standard.set(3, forKey: "amount_attempts")
                amountAttempts = 3
            }
            
            if attempted! < amountAttempts! {
                //                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                //                let vc = storyboard.instantiateViewController(identifier: "PasscodeController") as! PasscodeController
                //                vc.statusOfPasscode = .verifyPasscode
                //                vc.modalPresentationStyle = .fullScreen
                //                vc.completion = { success in
                //                    if success {
                //                        print (success)
                //                    } else {
                //                        print ("failed")
                //                    }
                //                }
                //                self.present(vc, animated: true)
            } else {
                //delete info
                print ("delete info")
            }
        }
    }
    
    private func configureTops() {
        title = "Save Data".localized()
        let rightButtonImage = UIImage(systemName: "icloud.and.arrow.up.fill")?.withRenderingMode(.alwaysTemplate)
        let rightButton = UIBarButtonItem(image: rightButtonImage, style: .plain, target: self, action: #selector(saveData))
        self.navigationItem.rightBarButtonItem = rightButton
        
        
        if traitCollection.userInterfaceStyle == .light {
            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "darkblueAccent")!
        } else {
            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "mainOrange")!
        }
    }
    
    @objc private func saveData() {
        if dataSelector.selectedSegmentIndex == 0 {
            saveDataCreditCard()
        } else {
            saveDataPassword()
        }
    }
    
}

//MARK: Save credit card information
extension NewDataController {
    @IBAction func dataSelectorChanged(_ sender: Any) {
        if dataSelector.selectedSegmentIndex == 0 {
            passwordView.isHidden = true
            creditCardView.isHidden = false
        } else {
            passwordView.isHidden = false
            creditCardView.isHidden = true
        }
        
    }
    
    @IBAction func scanCreditCard(_ sender: Any) {
        let vc = CreditCardScannerViewController(delegate: self)
        vc.titleLabelText = "Place card".localized()
        vc.subtitleLabelText = "Line up card within the lines"
        vc.labelTextColor = .white
        vc.cancelButtonTitleText = "Cancel".localized()
        vc.cancelButtonTitleTextColor = UIColor(named: "mainOrange")!
        vc.cameraViewCreditCardFrameStrokeColor = .white
        vc.cameraViewMaskLayerColor = .black
        vc.cameraViewMaskAlpha = 0.7
        vc.textBackgroundColor = .black
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    private func verifyEmptyField() -> Bool {
        var verify = false
        if nameDataText.text == "" ||
            nameOnCardText.text == "" ||
            numberCardText.text == "" ||
            securityCodeText.text == "" ||
            expirationDate == nil ||
            dateLabel.text == "Add Date".localized() {
            
            verify = false
            let alertController = UIAlertController(title: "Empty Fields".localized(), message: "You are trying to save empty information".localized(), preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        } else {
            verify = true
        }
        return verify
    }
    
    private func saveDataCreditCard() {
        
        if verifyEmptyField() {
            let dataToSave = LockData(nameData: nameDataText.text!, nameOnCard: nameOnCardText.text!, numberCard: numberCardText.text!, expDate: expirationDate!, securityCode: securityCodeText.text!)
            let encryptedData = encryptData(encrypt: true, lockData: dataToSave)
            
            DBManager.shared.saveEncryptedData(nameOfData: nameDataText.text!, contentData: encryptedData, userID: Auth.auth().currentUser!.uid) { success in
                if success {
                    let alertController = UIAlertController(title: "Saved".localized(), message: "Your information has been saved successfully".localized(), preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(action)
                    self.present(alertController, animated: true) { [self] in
                        self.nameDataText.text = ""
                        self.nameOnCardText.text = ""
                        self.numberCardText.text = ""
                        self.securityCodeText.text = ""
                        self.expirationDate = nil
                        self.dateLabel.text = "Add Date".localized()
                    }
                }
            }
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
    
}

//extension SaveDataController: UIPickerViewDelegate, UIPickerViewDataSource {
//
//    func configurePicker() {
//        monthPicker.delegate = self
//        monthPicker.dataSource = self
//        monthPickerData = [01, 02, 03, 04, 05, 06,07,08, 09, 10, 11, 12]
//        yearPickerData = [21, 22, 23,24,25,26]
//        monthNames = ["Jan".localized(), "Feb".localized(), "Mar".localized(), "Apr".localized(), "May".localized(), "Jun".localized(), "Jul".localized(), "Aug".localized(), "Sept".localized(), "Oct".localized(), "Nov".localized(), "Dec".localized()]
//    }
//
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 2
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        if component == 0 {
//            return monthPickerData.count
//        }
//        return yearPickerData.count
//    }
//
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        if component == 0 {
//            return String(monthPickerData[row])
//        }
//        return String(yearPickerData[row])
//    }
//
//
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//
//        let monthSelected = monthPickerData[pickerView.selectedRow(inComponent: 0)]
//        let yearSelected = yearPickerData[pickerView.selectedRow(inComponent: 1)]
//
//        let selectedDate = "\(monthNames[monthSelected-1])/\(yearSelected)"
//        expirationDate = "\(monthSelected)\(yearSelected)"
//        dateLabel.text = selectedDate
//    }
//}

extension NewDataController: CreditCardScannerViewControllerDelegate {
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
            numberCardText.text = number
        }
        
        if let name = card.name {
            nameOnCardText.text = name
        }
        
        if var yearDate = card.expireDate?.year, let monthDate = card.expireDate?.month {
            yearDate = yearDate - 2000
            //            dateLabel.text = "\(monthNames[monthDate - 1])/\(yearDate)"
            
            let tempYearPicker = yearDate - 21
            //            monthPicker.selectRow(monthDate - 1, inComponent: 0, animated: true)
            //            monthPicker.selectRow(tempYearPicker, inComponent: 1, animated: true)
            
        }
    }
}


//MARK: Save password
extension NewDataController {
    private func saveDataPassword() {
        if verifyPassFields() {
            var username = "N/A"
            if !usernamePassText.text!.isEmpty {
                username = usernamePassText.text!.replacingOccurrences(of: " ", with: "")
            }
            var email = "N/A"
            if !emailPassText.text!.isEmpty {
                email = emailPassText.text!.replacingOccurrences(of: " ", with: "")
            }
            
            let dataToSave = LockDataPassword(nameData: nameDataPassText.text!, username: username, email: email, password: passPassText.text!)
            if let encryptedData = encryptDataPassword(encrypt: true, lockDataPassword: dataToSave) {
                DBManager.shared.saveEncryptedDataPasswords(nameOfDataPassword: nameDataPassText.text!, contentDataPassword: encryptedData.contentData, user: encryptedData.userData!, userID: Auth.auth().currentUser!.uid) { success in
                    if success {
                        let alertController = UIAlertController(title: "Saved".localized(), message: "Your information has been saved successfully".localized(), preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alertController.addAction(action)
                        self.present(alertController, animated: true) { [self] in
                            self.nameDataPassText.text = ""
                            self.usernamePassText.text = ""
                            self.emailPassText.text = ""
                            self.passPassText.text = ""
                            self.verifyPassText.text = ""
                        }
                    }
                }
            }
        }
    }
    
    private func verifyPassFields() -> Bool {
        var verify = false
        
        if nameDataPassText.text == "" {
            verify = false
            let alertController = UIAlertController(title: "Empty Fields".localized(), message: "Please make sure to give a name to this account".localized(), preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        } else if passPassText.text != verifyPassText.text {
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
    
    private func encryptDataPassword(encrypt: Bool, lockDataPassword: LockDataPassword!) -> LNKData? {
        var userData = "\(lockDataPassword.username!) \(lockDataPassword.email!)"
        var passData = lockDataPassword.password
        let nameData = lockDataPassword.nameData
        
        let passcode = UserDefaults.standard.value(forKey: "general_passcode") as! String
        guard let secretKey = Auth.auth().currentUser?.uid else {
            passData.removeAll()
            userData.removeAll()
            return nil
        }
        
        let encryptedUserData = Encryption.shared.encryptDecrypt(oldMessage: userData, encryptedPasscode: passcode, secretKey: secretKey, encrypt: true)
        let encryptedContentData = Encryption.shared.encryptDecrypt(oldMessage: passData, encryptedPasscode: passcode, secretKey: secretKey, encrypt: true)
        
        let entryptedData = LNKData(nameData: nameData, userData: encryptedUserData, contentData: encryptedContentData)
        return entryptedData
    }
}

//extension String {
//    func group(by groupSize:Int=3, separator:String="-") -> String
//       {
//          if self.count <= groupSize   { return self }
//
//          let splitSize  = min(max(2,self.count-2) , groupSize)
//          let splitIndex = index(startIndex, offsetBy:splitSize)
//
//          return substring(to:splitIndex)
//               + separator
//               + substring(from:splitIndex).group(by:groupSize, separator:separator)
//       }
//}


//extension UITextField {
//    fileprivate func setPasswordToggleImage(_ button: UIButton) {
//        if(isSecureTextEntry){
//            button.setImage(UIImage(named: "eye"), for: .normal)
//        }else{
//            button.setImage(UIImage(named: "eye.slash"), for: .normal)
//
//        }
//    }
//    func enablePasswordToggle(){
//        let button = UIButton(type: .custom)
//        setPasswordToggleImage(button)
//        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
//        button.frame = CGRect(x: CGFloat(self.frame.size.width - 25), y: CGFloat(5), width: CGFloat(35), height: CGFloat(35))
//        button.addTarget(self, action: #selector(self.togglePasswordView), for: .touchUpInside)
//        self.rightView = button
//        self.rightViewMode = .always
//    }
//    @IBAction func togglePasswordView(_ sender: Any) {
//        self.isSecureTextEntry = !self.isSecureTextEntry
//        setPasswordToggleImage(sender as! UIButton)
//    }
//}
