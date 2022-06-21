//
//  Extensions.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/28/21.
//

import Foundation
import UIKit


//MARK: Extensios for keyboard
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIButton {
    func roundButton() {
        self.layer.cornerRadius = self.frame.size.height / 2
        self.layer.shadowOpacity = 0.1
        self.layer.shadowRadius = 2.0
        self.layer.shadowOffset = CGSize.init(width: 10, height: 5)
        self.layer.shadowColor = UIColor.lightGray.cgColor
    }
}


extension UITextField {
    fileprivate func setPasswordToggleImage(_ button: UIButton) {
        if(isSecureTextEntry){
            button.setImage(UIImage(named: "eye"), for: .normal)
            
            if traitCollection.userInterfaceStyle == .light {
                button.tintColor = UIColor(named: "darkblueAccent")!
            } else {
                button.tintColor = UIColor(named: "greenAccent")!
            }
        }else{
            button.setImage(UIImage(named: "eye.slash"), for: .normal)
            if traitCollection.userInterfaceStyle == .light {
                button.tintColor = UIColor(named: "greenAccent")!
            } else {
                button.tintColor = UIColor(named: "mainOrange")!
            }
            
        }
    }
    
    func enablePasswordToggle(){
        let button = UIButton(type: .custom)
        setPasswordToggleImage(button)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
        button.frame = CGRect(x: CGFloat(self.frame.size.width - 25), y: CGFloat(5), width: CGFloat(35), height: CGFloat(35))
        button.addTarget(self, action: #selector(self.togglePasswordView), for: .touchUpInside)
        self.rightView = button
        self.rightViewMode = .always
    }
    @IBAction func togglePasswordView(_ sender: Any) {
        self.isSecureTextEntry = !self.isSecureTextEntry
        setPasswordToggleImage(sender as! UIButton)
    }
}

extension String {
    func localized() -> String {
        return NSLocalizedString(
            self,
            tableName: "Localizable",
            bundle: .main,
            value: self,
            comment: self)
    }
    
    var cleanPasswordCharacters: String {
        let allowCharacters = Set("abcdefghijklmnopqrstuvwxyzQWERTYUIOPASDFGHJKLZXCVBNM1234567890_~!@#$%^&*()_+;':<>?/.,")
        return self.filter {allowCharacters.contains($0) }
    }
    
//    var isOnlyCharacters: Bool {
//        let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWYZ1234567890_~!@#$%^&*()_+;':<>?/.,")
//        if self.rangeOfCharacter(from: characterset.inverted) == nil {
//            return true
//        } else {
//            return false
//        }
//    }
//
//    var isValidPassword: Bool {
//        let allowCharacters = ".*[^A-Z0-9].*"
//        let testString = NSPredicate(format:"SELF MATCHES %@", allowCharacters)
//        return testString.evaluate(with: self)
//    }
    
    func hasCharacter(in characterSet: CharacterSet) -> Bool {
        return rangeOfCharacter(from: characterSet) != nil
    }
    
}






