//
//  GeneratePasswordController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 6/28/22.
//

import UIKit

class GeneratePasswordController: UIViewController {

    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var amountCharactersSlider: UISlider!
    @IBOutlet weak var capitalSwitch: UISwitch!
    @IBOutlet weak var digitsSwitch: UISwitch!
    @IBOutlet weak var symbolsSwitch: UISwitch!
    @IBOutlet weak var amountCharactersLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        amountCharactersSlider.isContinuous = false

        // Do any additional setup after loading the view.
        let amountCharacters = Int(amountCharactersSlider.value)
        amountCharactersLabel.text = String(amountCharacters)
        
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
    
    
    private func generatePassword() {
        let amountCharacters = Int(amountCharactersSlider.value)
        let randomPass = randomNonceString(length: amountCharacters)
        passwordLabel.text = randomPass
    }
    
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        
    }
    
    func randomNonceString(length: Int) -> String {
        var arrayString = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
        if capitalSwitch.isOn {
            arrayString += "ABCDEFGHIJKLMNOPQRSTUVXYZABCDEFGHIJKLMNOPQRSTUVXYZABCDEFGHIJKLMNOPQRSTUVXYZABCDEFGHIJKLMNOPQRSTUVXYZABCDEFGHIJKLMNOPQRSTUVXYZ"
        }
        if digitsSwitch.isOn {
            arrayString += "1234567890123456789012345678901234567890"
        }
        if symbolsSwitch.isOn {
            arrayString += "~!@#$%^&*()._+=-<>?,"
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
