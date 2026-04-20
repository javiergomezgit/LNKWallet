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

    // MARK: — Outlets
    @IBOutlet weak var accountNameTextField: UITextField!
    @IBOutlet weak var cardholderNameTextField: UITextField!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cardNumberTextField: UITextField!
    @IBOutlet weak var ccvTextField: UITextField!
    @IBOutlet weak var expirationButton: UIButton!
    @IBOutlet weak var zipCodeTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!

    // MARK: — Picker data
    let pickerView = UIPickerView()
    let monthPickerData = DateFormatter().monthSymbols.enumerated().map { "\($0.element.capitalized) - \($0.offset + 1)" }
    let yearPickerData = ["2025", "2026", "2027", "2028", "2029", "2030",
                          "2031", "2032", "2033", "2034", "2035", "2036", "2037"]
    let yearNumbers    = [25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37]

    // MARK: — State
    public var nameData = ""
    var secretKey   = ""
    var creationDate = 0
    var user = Auth.auth().currentUser

    // MARK: — Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        view.backgroundColor = .backgroundPrimary
        tableView.backgroundColor = .backgroundPrimary
        tableView.separatorColor = .border
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        setupNavBar()
        setupTextFields()
        setupExpirationButton()
        setupScanButton()
        setupPicker()
        setupUser()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !nameData.isEmpty {
            accountNameTextField.text = nameData
            accountNameTextField.isEnabled = false
            loadEncryptedDataCreditCard()
        }
    }

    // MARK: — Setup helpers

    private func setupNavBar() {
        styleFormNavBar(title: nameData.isEmpty ? "datacreditcard.title.new".localized() : "datacreditcard.title".localized())

        let closeBtn = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(exitButtonTapped))
        closeBtn.tintColor = .textSecondary
        navigationItem.leftBarButtonItem = closeBtn

        let saveBtn = UIBarButtonItem(title: nameData.isEmpty ? "button.save".localized() : "button.update".localized(),
                                     style: .done,
                                     target: self,
                                     action: #selector(saveButtonTapped))
        saveBtn.tintColor = .accentCards
        navigationItem.rightBarButtonItem = saveBtn
    }

    private func setupTextFields() {
        styleTextField(accountNameTextField,   placeholder: "datacreditcard.placeholder.nickname".localized(), accent: .accentCards)
        styleTextField(cardholderNameTextField, placeholder: "datacreditcard.placeholder.cardholder".localized(), accent: .accentCards)
        styleTextField(cardNumberTextField,    placeholder: "datacreditcard.placeholder.number".localized(), accent: .accentCards)
        styleTextField(ccvTextField,           placeholder: "datacreditcard.placeholder.cvv".localized(), accent: .accentCards)
        styleTextField(zipCodeTextField,       placeholder: "datacreditcard.placeholder.zip".localized(), accent: .accentCards)
        styleTextField(addressTextField,       placeholder: "datacreditcard.placeholder.address".localized(), accent: .accentCards)

        cardNumberTextField.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .regular)
        cardNumberTextField.delegate = self

        cardNumberTextField.keyboardType = .numberPad
        ccvTextField.keyboardType        = .numberPad
        zipCodeTextField.keyboardType    = .numberPad
        ccvTextField.isSecureTextEntry   = true
        addressTextField.keyboardType = .default
        addressTextField.textContentType = .fullStreetAddress
        addressTextField.autocorrectionType = .no
    }

    private func setupExpirationButton() {
        var config = UIButton.Configuration.plain()
        config.title                          = "datacreditcard.expiration.placeholder".localized()
        config.baseForegroundColor            = .textSecondary
        config.background.backgroundColor     = .backgroundSecondary
        config.background.strokeColor         = .border
        config.background.strokeWidth         = 0.5
        config.background.cornerRadius        = 10
        config.cornerStyle                    = .fixed
        expirationButton.configuration        = config
    }

    private func setupScanButton() {
        // Full-width tappable row — icon left + label
        var config = UIButton.Configuration.plain()
        config.image                      = UIImage(systemName: "camera.viewfinder")
        config.imagePlacement             = .leading
        config.imagePadding               = 10
        config.title                      = "datacreditcard.scan".localized()
        config.baseForegroundColor        = .accentCards
        config.background.backgroundColor = .clear
        cameraButton.configuration        = config
        cameraButton.contentHorizontalAlignment = .leading
    }

    private func setupPicker() {
        pickerView.delegate   = self
        pickerView.dataSource = self
        pickerView.frame      = CGRect(x: 0, y: 0, width: view.frame.width - 20, height: 200)
    }

    private func setupUser() {
        guard let u = user else { exit(0) }
        secretKey    = u.uid
        creationDate = Int(u.metadata.creationDate!.timeIntervalSince1970)
    }

    // MARK: — TableView section headers

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titles = [
            "datacreditcard.section.details".localized(),
            "datacreditcard.section.info".localized(),
            "datacreditcard.section.billing".localized()
        ]
        guard section < titles.count else { return nil }

        let container = UIView()
        container.backgroundColor = .backgroundPrimary

        let label = UILabel()
        label.text          = titles[section]
        label.font          = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor     = .accentCards
        label.letterSpacing = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        return container
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .backgroundPrimary
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }

    // MARK: — Actions

    @IBAction func exitButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @objc private func saveButtonTapped() {
        nameData.isEmpty ? saveData() : updateData()
    }

    @IBAction func cameraScannerTapped(_ sender: UIButton) {
        let vc = CreditCardScannerViewController(delegate: self)
        vc.titleLabelText                      = "datacreditcard.scanner.place".localized()
        vc.subtitleLabelText                   = "datacreditcard.scanner.lineup".localized()
        vc.labelTextColor                      = .white
        vc.cancelButtonTitleText               = "button.cancel".localized()
        vc.cancelButtonTitleTextColor          = .accentBrand
        vc.cameraViewCreditCardFrameStrokeColor = .white
        vc.cameraViewMaskLayerColor            = .black
        vc.cameraViewMaskAlpha                 = 0.7
        vc.textBackgroundColor                 = .black
        vc.modalPresentationStyle              = .fullScreen
        present(vc, animated: true)
    }

    @IBAction func expirationButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "datacreditcard.expiration.title".localized(), message: "", preferredStyle: .actionSheet)
        alert.isModalInPresentation = false
        alert.view.addSubview(pickerView)

        let heightConstraint = NSLayoutConstraint(
            item: alert.view!, attribute: .height,
            relatedBy: .equal,
            toItem: nil, attribute: .notAnAttribute,
            multiplier: 1, constant: view.frame.height / 3)
        alert.view.addConstraint(heightConstraint)

        let selectAction = UIAlertAction(title: "datacreditcard.select_date".localized(), style: .default) { _ in
            let month      = self.pickerView.selectedRow(inComponent: 0) + 1
            let yearOffset = self.pickerView.selectedRow(inComponent: 1)
            let year       = self.yearNumbers[yearOffset]
            let dateString = "\(month) / \(year)"
            var config                    = self.expirationButton.configuration
            config?.title                 = dateString
            config?.baseForegroundColor   = .textPrimary
            self.expirationButton.configuration = config
        }
        alert.addAction(selectAction)
        present(alert, animated: true)
    }

    // MARK: — Data operations

    private func loadEncryptedDataCreditCard() {
        DBManager.shared.getEncryptedDataCreditCard(userID: user!.uid, nameData: nameData) { [weak self] card in
            guard let self = self, let card = card else { return }
            let d = self.decryptDataCreditCard(lnkDataCreditCard: card)
            self.cardholderNameTextField.text = d.nameOnCard
            self.cardNumberTextField.text     = d.numberCard
            self.ccvTextField.text            = d.securityCode
            self.zipCodeTextField.text        = d.zipCode
            self.addressTextField.text        = d.address

            var config                  = self.expirationButton.configuration
            config?.title               = d.expDate
            config?.baseForegroundColor = .textPrimary
            self.expirationButton.configuration = config
        }
    }

    private func saveData() {
        guard verifyEmptyField(), let encrypted = encryptDataCreditCard() else { return }
        DBManager.shared.saveEncryptedCreditCard(
            nameOfData: accountNameTextField.text!.sanitizeNameForDB(),
            lnkDataCreditCard: encrypted,
            userID: user!.uid) { [weak self] success in
            guard let self = self, success else { return }
            self.showAlert(title: "alert.saved.title".localized(), message: "datacreditcard.saved.message".localized()) {
                self.clearForm()
            }
        }
    }

    private func updateData() {
        guard verifyEmptyField(), let encrypted = encryptDataCreditCard() else { return }
        DBManager.shared.updateEncryptedCreditCard(
            nameOfData: accountNameTextField.text!.sanitizeNameForDB(),
            lnkDataCreditCard: encrypted,
            userID: user!.uid) { [weak self] success in
            guard let self = self, success else { return }
            self.showAlert(title: "alert.updated.title".localized(), message: "datacreditcard.updated.message".localized()) {
                self.dismiss(animated: true)
            }
        }
    }

    private func clearForm() {
        accountNameTextField.text    = ""
        cardholderNameTextField.text = ""
        cardNumberTextField.text     = ""
        ccvTextField.text            = ""
        zipCodeTextField.text        = ""
        var config                   = expirationButton.configuration
        config?.title                = "datacreditcard.expiration.placeholder".localized()
        config?.baseForegroundColor  = .textSecondary
        expirationButton.configuration = config
    }

    // MARK: — Encryption helpers

    private func encryptDataCreditCard() -> LNKDataCreditCard? {
        let e = Encryption.shared.encryptDecrypt
        let p = String(creationDate)
        return LNKDataCreditCard(
            nameData:     e(accountNameTextField.text!,    p, secretKey, true),
            nameOnCard:   e(cardholderNameTextField.text!, p, secretKey, true),
            numberCard:   e(cardNumberTextField.text!,     p, secretKey, true),
            securityCode: e(ccvTextField.text!,            p, secretKey, true),
            zipCode:      e(zipCodeTextField.text!,        p, secretKey, true),
            expDate:      e(expirationButton.titleLabel!.text!, p, secretKey, true),
            address:      e(addressTextField.text!,        p, secretKey, true)
        )
    }

    private func decryptDataCreditCard(lnkDataCreditCard c: LNKDataCreditCard) -> LNKDataCreditCard {
        let d = Encryption.shared.encryptDecrypt
        let p = String(creationDate)
        return LNKDataCreditCard(
            nameData:     d(c.nameData,     p, secretKey, false),
            nameOnCard:   d(c.nameOnCard,   p, secretKey, false),
            numberCard:   d(c.numberCard,   p, secretKey, false),
            securityCode: d(c.securityCode, p, secretKey, false),
            zipCode:      d(c.zipCode,      p, secretKey, false),
            expDate:      d(c.expDate,      p, secretKey, false),
            address:      d(c.address,      p, secretKey, false)
        )
    }

    private func verifyEmptyField() -> Bool {
        let expTitle = expirationButton.configuration?.title ?? ""
        let allFilled = ![accountNameTextField.text,
                          cardholderNameTextField.text,
                          cardNumberTextField.text,
                          ccvTextField.text].contains("")
                        && !expTitle.isEmpty && expTitle != "datacreditcard.expiration.placeholder".localized()
        if !allFilled {
            showAlert(title: "alert.empty_fields.title".localized(), message: "alert.empty_fields.message".localized())
        }
        return allFilled
    }

    // MARK: — Alert helper

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "button.ok".localized(), style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

// MARK: — UIPickerView

extension DataCreditCardController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        component == 0 ? monthPickerData.count : yearPickerData.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        component == 0 ? monthPickerData[row] : yearPickerData[row]
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 46 }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        view.frame.width / 2.5
    }
}

// MARK: — CreditCardScanner

extension DataCreditCardController: CreditCardScannerViewControllerDelegate {

    func creditCardScannerViewControllerDidCancel(_ vc: CreditCardScannerViewController) {
        vc.dismiss(animated: true)
    }

    func creditCardScannerViewController(_ vc: CreditCardScannerViewController,
                                         didErrorWith error: CreditCardScannerError) {
        print(error.errorDescription ?? "Scanner error")
        vc.dismiss(animated: true)
    }

    func creditCardScannerViewController(_ vc: CreditCardScannerViewController,
                                         didFinishWith card: CreditCard) {
        vc.dismiss(animated: true)

        if let number = card.number { cardNumberTextField.text = number }
        if let name   = card.name   { cardholderNameTextField.text = name }

        if var year = card.expireDate?.year, let month = card.expireDate?.month {
            year -= 2000
            var config                  = expirationButton.configuration
            config?.title               = "\(month) / \(year)"
            config?.baseForegroundColor = .textPrimary
            expirationButton.configuration = config
        }
        
        if let number = card.number {
            cardNumberTextField.text = formatCardNumber(number)
        }
    }
    
    private func formatCardNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }.prefix(16)
        return stride(from: 0, to: digits.count, by: 4).map { i -> String in
            let start = digits.index(digits.startIndex, offsetBy: i)
            let end   = digits.index(start, offsetBy: min(4, digits.count - i))
            return String(digits[start..<end])
        }.joined(separator: " ")
    }
}

// MARK: — UILabel letter spacing helper

private extension UILabel {
    var letterSpacing: CGFloat {
        get { 0 }
        set {
            guard let text = text else { return }
            let attributed = NSMutableAttributedString(string: text)
            attributed.addAttribute(.kern,
                                    value: newValue,
                                    range: NSRange(location: 0, length: text.count))
            attributedText = attributed
        }
    }
}


// MARK: UITextFieldDelegate extension
extension DataCreditCardController: UITextFieldDelegate {

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool

    {
        // — Card number grouping
        if textField == cardNumberTextField {
            let current = (textField.text ?? "") as NSString
            let updated = current.replacingCharacters(in: range, with: string)
            let digits  = updated.filter { $0.isNumber }

            // Max 16 digits
            guard digits.count <= 16 else { return false }

            // Format: XXXX XXXX XXXX XXXX
            let grouped = stride(from: 0, to: digits.count, by: 4).map { i -> String in
                let start = digits.index(digits.startIndex, offsetBy: i)
                let end   = digits.index(start, offsetBy: min(4, digits.count - i))
                return String(digits[start..<end])
            }.joined(separator: " ")

            textField.text = grouped
            return false
        }

        // — ZIP max 5 digits
        if textField == zipCodeTextField {
            let current = (textField.text ?? "") as NSString
            let updated = current.replacingCharacters(in: range, with: string)
            let digits  = updated.filter { $0.isNumber }
            guard digits.count <= 5 else { return false }
            textField.text = String(digits)
            return false
        }

        return true
    }
}
