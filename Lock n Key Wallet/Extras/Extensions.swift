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
    
    func styleFormNavBar(title: String, accent: UIColor = .accentBrand) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .backgroundPrimary
        appearance.shadowColor = .border
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.title = title
    }
    
    func styleTextField(_ textField: UITextField,
                        placeholder: String,
                        accent: UIColor = .accentBrand) {
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 15)
        textField.textColor = .textPrimary
        textField.backgroundColor = .backgroundSecondary
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = 0.5
        textField.layer.borderColor = UIColor.border.cgColor
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
    }
    
    func styleTextView(_ textView: UITextView) {
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = .textPrimary
        textView.backgroundColor = .backgroundSecondary
        textView.layer.cornerRadius = 10
        textView.layer.masksToBounds = true
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.border.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
    }
    
    func stylePrimaryButton(_ button: UIButton, title: String, accent: UIColor = .accentBrand) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = accent
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            return a
        }
        button.configuration = config
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
        if isSecureTextEntry {
            if #available(iOS 15.0, *) {
                var config = button.configuration ?? UIButton.Configuration.plain()
                config.image = UIImage(named: "eye")
                button.configuration = config
            } else {
                button.setImage(UIImage(named: "eye"), for: .normal)
            }
            button.tintColor = .accentBrand
        } else {
            if #available(iOS 15.0, *) {
                var config = button.configuration ?? UIButton.Configuration.plain()
                config.image = UIImage(named: "eye.slash")
                button.configuration = config
            } else {
                button.setImage(UIImage(named: "eye.slash"), for: .normal)
            }
            button.tintColor = .textSecondary
        }
    }
    
    func enablePasswordToggle() {
        let button = UIButton(type: .custom)
        setPasswordToggleImage(button)

        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addTarget(self, action: #selector(self.togglePasswordView), for: .touchUpInside)

        // Wrap in a container to control right padding
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 52, height: 44))
        button.center = CGPoint(x: 22, y: 22)
        container.addSubview(button)

        self.rightView     = container
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
    
    func sanitizeNameForDB() -> String {
        return self
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
        self.addInteraction(UIContextMenuInteraction(delegate: self))
    }
}

extension CopyableLabel: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
                UIPasteboard.general.string = self?.text
            }
            return UIMenu(title: "", children: [copyAction])
        }
    }
}

