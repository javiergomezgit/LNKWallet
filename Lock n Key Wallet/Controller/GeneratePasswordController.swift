//
//  GeneratePasswordController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 6/28/22.
//

import UIKit
import Indicate

class GeneratePasswordController: UIViewController {

    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var amountCharactersSlider: UISlider!
    @IBOutlet weak var capitalSwitch: UISwitch!
    @IBOutlet weak var digitsSwitch: UISwitch!
    @IBOutlet weak var symbolsSwitch: UISwitch!
    @IBOutlet weak var amountCharactersLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var viewBackPassword: UIView!
    @IBOutlet weak var copiedView: UIView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        copyButton.roundCorners(amountCornerPercentage: 30)
        copyButton.setTitle("", for: .normal)
        resetButton.roundCorners(amountCornerPercentage: 30)
        resetButton.setTitle("", for: .normal)
        
        amountCharactersSlider.isContinuous = false
        passwordLabel.text = "P@55W#RD"
        let amountCharacters = passwordLabel.text!.count
        amountCharactersLabel.text = String(amountCharacters)
        amountCharactersSlider.value = Float(amountCharacters)
        
        generatePassword()
    }
        
    @IBAction func capitalLetterChanged(_ sender: UISwitch) {
        generatePassword()
    }
    
    @IBAction func digitsChanged(_ sender: UISwitch) {
        generatePassword()
    }
    
    @IBAction func symbolsChanged(_ sender: UISwitch) {
        generatePassword()
    }
    
    @IBAction func regenerateButtonTapped(_ sender: UIButton) {
        generatePassword()
    }
    
    @IBAction func amountCharactersChanged(_ sender: UISlider) {
        generatePassword()
        
        sender.setValue(sender.value.rounded(.down), animated: true)
        print(sender.value)
        
        amountCharactersLabel.text = String(Int(sender.value))
    }
    
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
         pasteboard.string = passwordLabel.text
        
        let content = Indicate.Content(title: .init(value: " COPIED 👍", alignment: .center))//,
                                       //attachment: .emoji(.init(value: "👍", alignment: .natural)))

        let config = Indicate.Configuration()
            .with(backgroundColor: .label)
            .with(titleColor: .systemBackground)
            .with(duration: 2)
            .with(tap: { controller in
                controller.dismiss()
            })

        let controller = Indicate.PresentationController(content: content, configuration: config)
        controller.present(in: copiedView)
    }
    
    
    private func generatePassword() {
        let amountCharacters = Int(amountCharactersSlider.value)
        let randomPass = randomNonceString(length: amountCharacters)
        passwordLabel.text = randomPass
    }
    
    private func randomNonceString(length: Int) -> String {
        var arrayString = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
        if capitalSwitch.isOn {
            arrayString += "ABCDEFGHIJKLMNOPQRSTUVXYZABCDEFGHIJKLMNOPQRSTUVXYZ"
        }
        if digitsSwitch.isOn {
            arrayString += "1234567890123456789012345678901234567890"
        }
        if symbolsSwitch.isOn {
            arrayString += "~!@#$%^&*().,_+=-<>?"
        }
        let charset: Array<Character> = Array(arrayString)
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}


