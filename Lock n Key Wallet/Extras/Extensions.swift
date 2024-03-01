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
    
    
    ///Round the corners of button, with given percentage
    func roundCorners(amountCornerPercentage: CGFloat) {
        var smallerSideCorner = self.frame.height / 2
        if self.frame.height > self.frame.width {
            smallerSideCorner = self.frame.width / 2
        }
        self.layer.cornerRadius = (smallerSideCorner * amountCornerPercentage) / 100
        self.layer.shadowOpacity = 0.05
        self.layer.shadowRadius = 1.0
        self.layer.shadowOffset = CGSize.init(width: 3, height: 3)
        self.layer.shadowColor = UIColor.lightGray.cgColor
    }
}



extension UIImageView {
    func cornersImage(circleImage: Bool, border: Bool, roundedCorner: CGFloat?) {
        if border {
            self.layer.borderWidth = 0.5
            self.layer.borderColor = UIColor.lightGray.cgColor
        }
        self.layer.masksToBounds = false

        if circleImage {
            self.layer.cornerRadius = self.frame.height / 2
        } else {
            if roundedCorner != nil {
                self.layer.cornerRadius = self.frame.height / roundedCorner!
            } else {
                self.layer.cornerRadius = self.frame.height / 10 //In case that is not round image and user forgets to set the corners
            }
        }
        self.clipsToBounds = true
    }
}

extension UIView {
    func cornersView(border: Bool, roundedCorner: CGFloat?) {
        if border {
            self.layer.borderWidth = 0.5
            let color = UIColor.lightGray.withAlphaComponent(0.5)
//            self.layer.borderColor = UIColor.lightGray.cgColor
            self.layer.borderColor = color.cgColor //.init(gray: UIColor.lightGray.cgColor as! CGFloat, alpha: 0.5)
        }
        self.layer.masksToBounds = false

        if roundedCorner != nil {
            self.layer.cornerRadius = self.frame.height / roundedCorner!
        } else {
            self.layer.cornerRadius = self.frame.height / 10 //In case that is not round image and user forgets to set the corners
        }
        self.clipsToBounds = true
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


class CopyableLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sharedInit()
    }

    func sharedInit() {
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.showMenu)))
    }

    @objc func showMenu(sender: AnyObject?) {
        self.becomeFirstResponder()

        let menu = UIMenuController.shared

        if !menu.isMenuVisible {
            menu.showMenu(from: self, rect: self.bounds)
        }
    }

    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general

        board.string = text

        let menu = UIMenuController.shared

        menu.showMenu(from: self, rect: self.bounds)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
}




