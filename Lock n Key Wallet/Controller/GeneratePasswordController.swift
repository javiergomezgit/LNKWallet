//
//  GeneratePasswordController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 6/28/22.
//

import UIKit
//import Indicate

class GeneratePasswordController: UIViewController {

    // MARK: — Outlets
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var amountCharactersSlider: UISlider!
    @IBOutlet weak var capitalSwitch: UISwitch!
    @IBOutlet weak var digitsSwitch: UISwitch!
    @IBOutlet weak var symbolsSwitch: UISwitch!
    @IBOutlet weak var amountCharactersLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var viewBackPassword: UIView!
//    @IBOutlet weak var copiedView: UIView!

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary

        setupNavBar()
        setupPasswordDisplay()
        setupSlider()
        setupSwitches()
        setupButtons()
        setupFonts()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(passwordLabelTapped))
        passwordLabel.isUserInteractionEnabled = true
        passwordLabel.addGestureRecognizer(tap)

        amountCharactersSlider.isContinuous = false
        let initial = 12
        amountCharactersSlider.value = Float(initial)
        amountCharactersLabel.text   = "\(initial)"

        generatePassword()
    }

    // MARK: — Setup

    private func setupNavBar() {
        title = "Generator"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = []

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .backgroundPrimary
        appearance.shadowColor     = .clear
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary
        ]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance    = appearance

        // Back button tint
        navigationController?.navigationBar.tintColor = .accentBrand
    }

    private func setupPasswordDisplay() {
        viewBackPassword.backgroundColor    = .backgroundSecondary
        viewBackPassword.layer.cornerRadius = 16
        viewBackPassword.layer.borderWidth  = 0.5
        viewBackPassword.layer.borderColor  = UIColor.border.cgColor
        viewBackPassword.clipsToBounds      = true

        passwordLabel.font          = UIFont.monospacedSystemFont(ofSize: 28, weight: .bold)
        passwordLabel.textColor     = .textPrimary
        passwordLabel.textAlignment = .center
        passwordLabel.adjustsFontSizeToFitWidth = true
        passwordLabel.minimumScaleFactor        = 0.5
    }

    private func setupSlider() {
        amountCharactersSlider.minimumValue        = 6
        amountCharactersSlider.maximumValue        = 32
        amountCharactersSlider.minimumTrackTintColor = .accentBrand
        amountCharactersSlider.thumbTintColor        = .accentBrand

        amountCharactersLabel.font      = UIFont.systemFont(ofSize: 17, weight: .semibold)
        amountCharactersLabel.textColor = .textPrimary
        amountCharactersLabel.textAlignment = .center
    }

    private func setupSwitches() {
        [capitalSwitch, digitsSwitch, symbolsSwitch].forEach {
            $0?.onTintColor = .accentBrand
            $0?.thumbTintColor = .white
        }
    }

    private func setupButtons() {
        // Copy — filled gold
        var copyConfig = UIButton.Configuration.filled()
        copyConfig.title               = "Copy"
        copyConfig.image               = UIImage(systemName: "doc.on.doc")
        copyConfig.imagePlacement      = .leading
        copyConfig.imagePadding        = 8
        copyConfig.baseForegroundColor = .backgroundPrimary
        copyConfig.baseBackgroundColor = .accentBrand
        copyConfig.cornerStyle         = .capsule
        copyButton.configuration       = copyConfig

        // Regenerate — filled gold, slightly transparent
        var resetConfig = UIButton.Configuration.filled()
        resetConfig.title               = "Refresh"
        resetConfig.image               = UIImage(systemName: "arrow.clockwise")
        resetConfig.imagePlacement      = .leading
        resetConfig.imagePadding        = 8
        resetConfig.baseForegroundColor = .backgroundPrimary
        resetConfig.baseBackgroundColor = UIColor.accentBrand.withAlphaComponent(0.6)
        resetConfig.cornerStyle         = .capsule
        resetButton.configuration       = resetConfig
    }
    
    private func setupFonts() {
        // Amount label
        amountCharactersLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)

        // Password display — keep monospaced, it's intentional for passwords
        passwordLabel.font = UIFont.monospacedSystemFont(ofSize: 28, weight: .bold)
    }

    // MARK: — Actions

    @IBAction func capitalLetterChanged(_ sender: UISwitch) { generatePassword() }
    @IBAction func digitsChanged(_ sender: UISwitch)        { generatePassword() }
    @IBAction func symbolsChanged(_ sender: UISwitch)       { generatePassword() }

    @IBAction func regenerateButtonTapped(_ sender: UIButton) { generatePassword() }

    @IBAction func amountCharactersChanged(_ sender: UISlider) {
        sender.setValue(sender.value.rounded(.down), animated: true)
        amountCharactersLabel.text = "\(Int(sender.value))"
        generatePassword()
    }

    @IBAction func copyButtonTapped(_ sender: UIButton) {
        UIPasteboard.general.string = passwordLabel.text
        showToast("Password copied")
    }
    
    @objc private func passwordLabelTapped() {
        UIPasteboard.general.string = passwordLabel.text
        showToast("Password copied")
    }
    
    private func showToast(_ message: String) {
        // Remove any existing toast
        view.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }

        let toast = UILabel()
        toast.tag             = 999
        toast.text            = message
        toast.font            = UIFont.systemFont(ofSize: 14, weight: .medium)
        toast.textColor       = .backgroundPrimary
        toast.backgroundColor = UIColor.textPrimary.withAlphaComponent(0.85)
        toast.textAlignment   = .center
        toast.layer.cornerRadius = 20
        toast.layer.masksToBounds = true
        toast.alpha           = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: copyButton.topAnchor, constant: -24),
            toast.heightAnchor.constraint(equalToConstant: 40),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 180)
        ])

        UIView.animate(withDuration: 0.25, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.4, delay: 1.8, animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }

    // MARK: — Password generation

    private func generatePassword() {
        let length = Int(amountCharactersSlider.value)
        passwordLabel.text = randomNonceString(length: length)
    }

    private func randomNonceString(length: Int) -> String {
        var charset = "abcdefghijklmnopqrstuvwxyz"
        if capitalSwitch.isOn  { charset += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if digitsSwitch.isOn   { charset += "0123456789" }
        if symbolsSwitch.isOn  { charset += "~!@#$%^&*().,_+=-<>?" }

        let chars: [Character] = Array(charset)
        var result = ""
        var remaining = length

        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var byte: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)
                if status != errSecSuccess {
                    fatalError("SecRandomCopyBytes failed: \(status)")
                }
                return byte
            }
            for byte in randoms {
                guard remaining > 0 else { break }
                if byte < chars.count {
                    result.append(chars[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }
}

