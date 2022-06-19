//
//  PasscodeController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/23/21.
//

import UIKit
import FirebaseAuth
import CloudKit

class MasterPasswordController: UIViewController {
    
    @IBOutlet weak var passwordText: UITextField!
    
    
    @IBAction func passwordButtonTapped(_ sender: Any) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        
      
    }
    
    /*
    var NSApp: UIApplication!

    public var completion: ((Bool) -> (Void))?
    
    @IBOutlet weak var passwordStackView: UIStackView!
    @IBOutlet weak var label: UILabel!
    
    //Modified Password container - Code below
    var passwordContainerView: PasswordContainerView!
    var kPasswordDigit = 6
    var generalPasscode = ""
    var tempPasscode: String?
    var verified = false
    var statusOfPasscode = status.settingPasscode
    var updatePasscode = false
    var firebaseID = ""
    private var encryptedPasscode = ""
    
    private let database = CKContainer(identifier: "iCloud.com.jdev.Lock-n-Key-Wallet").publicCloudDatabase
    private let recordTypeName = "Passcodes"
    private let passcodeNameDB = "encrypted_passcode"
    private let firebaseNameDB = "firebase_id"
    
    enum status {
        case settingPasscode
        case verifyPasscode
        case changePasscode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passwordContainerView = PasswordContainerView.create(in: passwordStackView, digit: kPasswordDigit)
        passwordContainerView.delegate = self
        passwordContainerView.deleteButtonLocalizedTitle = "Delete".localized()
        passwordContainerView.touchAuthenticationEnabled = false
//        passwordContainerView.tintColor = UIColor(named: "darkblueAccent")
//        passwordContainerView.layer.borderColor = UIColor.red.cgColor
//        passwordContainerView.highlightedColor = .systemOrange
        
        if let id = Auth.auth().currentUser?.uid {
            self.firebaseID = id
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if statusOfPasscode == .verifyPasscode {
            downloadGeneralPasscode()
            label.text = "Current Passcode".localized()
        }
        if statusOfPasscode == .changePasscode {
            label.text = "Current Passcode".localized()
            downloadGeneralPasscode()
        }
        if statusOfPasscode == .settingPasscode {
            label.text = "Set Passcode".localized()
            //downloadGeneralPasscode()
        }
    }
    
    private func downloadGeneralPasscode() {
        //Download from firebase if status is verify or change
        let query = CKQuery(recordType: recordTypeName, predicate: NSPredicate(value: true))
        let ckRecordZoneID = CKRecordZone.ID(zoneName: "_defaultZone", ownerName: CKCurrentUserDefaultName)
        database.perform(query, inZoneWith: ckRecordZoneID) { [weak self] records, error in
            guard let records = records, error == nil else {
                return
            }
            
            for record in records {
                let id = record.value(forKey: self!.firebaseNameDB) as! String
                if id == self!.firebaseID {
                    print ("found general passcode")
                    self?.generalPasscode = record.value(forKey: self!.passcodeNameDB) as! String
                    UserDefaults.standard.set(true, forKey: "found_passcode")
                } else {
                    UserDefaults.standard.set(false, forKey: "found_passcode")
                    self?.completion!(false)
                }
            }
        }
    }
    
    private func setupPasscode() {
        let encryptedPasscode = Encryption.shared.encryptPasscode(passcode: generalPasscode, encrypt: true)
        
        let ckRecordZoneID = CKRecordZone.ID(zoneName: "_defaultZone", ownerName: CKCurrentUserDefaultName)
        let ckRecordID = CKRecord.ID(recordName: firebaseID, zoneID: ckRecordZoneID)
        let record = CKRecord(recordType: recordTypeName, recordID: ckRecordID)
        record.setValue(encryptedPasscode, forKey: passcodeNameDB)
        record.setValue(firebaseID, forKey: firebaseNameDB)
        
        if updatePasscode {
            updateGeneralPasscode()
        } else {
            database.save(record) { record, error in
                if record != nil, error == nil {
                    print ("saved")
                    UserDefaults.standard.set(encryptedPasscode, forKey: "general_passcode")
                    UserDefaults.standard.set(true, forKey: "found_passcode")
                    UserDefaults.standard.set(true, forKey: "passcode_saved")
                }
            }
        }
    }
    
    private func updateGeneralPasscode() {
        let encryptedPasscode = Encryption.shared.encryptPasscode(passcode: generalPasscode, encrypt: true)
        let recordID = CKRecord.ID(recordName: firebaseID)
        
        database.fetch(withRecordID: recordID) { record, error in
            if let record = record, error == nil {
                record.setValue(encryptedPasscode, forKey: self.passcodeNameDB)
                self.database.save(record) { result, error in
                    //TODO: Go wherever goes after updating
                    print ("record update")
                }
            }
        }
    }
    
}

extension PasscodeController: PasswordInputCompleteProtocol {
    
    func passwordInputComplete(_ passwordContainerView: PasswordContainerView, input: String) {
        switch statusOfPasscode {
            
        case .settingPasscode:
            if self.tempPasscode == nil {
                self.tempPasscode = input
                self.passwordContainerView.clearInput()
                self.label.text = "Confirm Passcode"
            } else {
                if tempPasscode == input {
                    self.generalPasscode = input
                    self.validationSuccess()
                } else {
                    self.validationFail()
                }
            }
        case .verifyPasscode:
            if validation(input) {
                validationSuccess()
            } else {
                validationFail()
            }
        case .changePasscode:
            if validation(input) {
                validationSuccess()
            } else {
                validationFail()
            }
        }
    }
    
    func touchAuthenticationComplete(_ passwordContainerView: PasswordContainerView, success: Bool, error: Error?) {
        if success {
            //            self.validationSuccess()
            print (success)
        } else {
            passwordContainerView.clearInput()
        }
    }
}

private extension PasscodeController {
    
    func validation(_ input: String) -> Bool {
        var isValid = false
        
        switch statusOfPasscode {
        case .settingPasscode:
            isValid = true
            generalPasscode = input
        case .verifyPasscode:
            let decryptedPasscode = Encryption.shared.encryptPasscode(passcode: generalPasscode, encrypt: false)
            if input == decryptedPasscode {
                self.encryptedPasscode = generalPasscode
                isValid = true
            }
        case .changePasscode:
            let generalPass = Encryption.shared.encryptPasscode(passcode: generalPasscode, encrypt: false)
            if input == generalPass && !verified {
                passwordContainerView.clearInput()
                label.text = "New Passcode".localized()
                verified = true
                break
            } else {
                if tempPasscode == nil && verified {
                    tempPasscode = input
                    passwordContainerView.clearInput()
                    label.text = "Confirm Passcode".localized()
                } else {
                    if tempPasscode == input {
                        self.generalPasscode = input
                        isValid = true
                    }
                }
            }
        }
        return isValid
    }
    
    func validationSuccess() {
        switch statusOfPasscode {
        case .settingPasscode:
            setupPasscode()
            print ("going completion")
            self.completion!(true)
            dismiss(animated: true)
        case .verifyPasscode:
            UserDefaults.standard.set(self.encryptedPasscode, forKey: "general_passcode")
            self.completion!(true)
            dismiss(animated: true, completion: nil)
        case .changePasscode:
            updateGeneralPasscode()
        }
    }
    
    func validationFail() {
        
        if statusOfPasscode != .settingPasscode {
            UserDefaults.standard.set("0", forKey: "wrong_passcode")
            let attempted = UserDefaults.standard.value(forKey: "attemptedPasscode") as! Int
            let amountAttempts = UserDefaults.standard.value(forKey: "amount_attempts") as! Int
            if attempted < amountAttempts {
                UserDefaults.standard.set(attempted + 1, forKey: "attemptedPasscode")
                let message = "Your data will be erased. You have ".localized() + String(amountAttempts - attempted) + " more attempt".localized()
                let alertController = UIAlertController(title: "Security".localized(), message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true)
            } else {
                DBManager.shared.deleteAllDatas(userID: Auth.auth().currentUser!.uid) { success in
                    if success {
                        DBManager.shared.deletePasscode(userID: Auth.auth().currentUser!.uid) { success in
                            if success {
                                UserDefaults.standard.set(0, forKey: "attemptedPasscode")
                                UserDefaults.standard.set(3, forKey: "amount_attempts")
                                exit(0);
                            }
                        }
                    }
                }
            }
            
            UserDefaults.standard.removeObject(forKey: "general_passcode")
            UserDefaults.standard.synchronize()
        }
        
        passwordContainerView.wrongPassword()
        completion!(false)
    }
    */
}



/*
 == Password Container Modified ==
 
 
 //
 //  PasswordView.swift
 //
 //  Created by rain on 4/21/16.
 //  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
 //

 import UIKit
 import LocalAuthentication

 public protocol PasswordInputCompleteProtocol: class {
     func passwordInputComplete(_ passwordContainerView: PasswordContainerView, input: String)
     func touchAuthenticationComplete(_ passwordContainerView: PasswordContainerView, success: Bool, error: Error?)
 }

 open class PasswordContainerView: UIView {
     
     //MARK: IBOutlet
     @IBOutlet open var passwordInputViews: [PasswordInputView]!
     @IBOutlet open weak var passwordDotView: PasswordDotView!
     @IBOutlet open weak var deleteButton: UIButton!
     @IBOutlet open weak var touchAuthenticationButton: UIButton!
     
     //MARK: Property
     open var deleteButtonLocalizedTitle: String = "" {
         didSet {
             deleteButton.setTitle(NSLocalizedString(deleteButtonLocalizedTitle, comment: ""), for: .normal)
         }
     }
     
     open weak var delegate: PasswordInputCompleteProtocol?
     fileprivate var touchIDContext = LAContext()
     
     fileprivate var inputString: String = "" {
         didSet {
             #if swift(>=3.2)
                 passwordDotView.inputDotCount = inputString.count
             #else
                 passwordDotView.inputDotCount = inputString.characters.count
             #endif
             
             checkInputComplete()
         }
     }
     
     open var isVibrancyEffect = false {
         didSet {
             configureVibrancyEffect()
         }
     }
     
     open override var tintColor: UIColor! {
         didSet {
             guard !isVibrancyEffect else { return }
             deleteButton.setTitleColor(tintColor, for: .normal)
             passwordDotView.strokeColor = tintColor
             touchAuthenticationButton.tintColor = tintColor
             passwordInputViews.forEach {
                 $0.textColor = tintColor
                 $0.borderColor = tintColor
             }
         }
     }
     
     open var highlightedColor: UIColor! {
         didSet {
             guard !isVibrancyEffect else { return }
             passwordDotView.fillColor = highlightedColor
             passwordInputViews.forEach {
                 $0.highlightBackgroundColor = highlightedColor
             }
         }
     }
     
     open var isTouchAuthenticationAvailable: Bool {
         return touchIDContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
     }
     
     open var touchAuthenticationEnabled = false {
         didSet {
             let enable = (isTouchAuthenticationAvailable && touchAuthenticationEnabled)
             touchAuthenticationButton.alpha = enable ? 1.0 : 0.0
             touchAuthenticationButton.isUserInteractionEnabled = enable
         }
     }
     
     open var touchAuthenticationReason = "Touch to unlock"
     
     //MARK: AutoLayout
     open var width: CGFloat = 0 {
         didSet {
             self.widthConstraint.constant = width
         }
     }
     fileprivate let kDefaultWidth: CGFloat = 288
     fileprivate let kDefaultHeight: CGFloat = 410
     fileprivate var widthConstraint: NSLayoutConstraint!
     
     fileprivate func configureConstraints() {
         let ratioConstraint = widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: kDefaultWidth / kDefaultHeight)
         self.widthConstraint = widthAnchor.constraint(equalToConstant: kDefaultWidth)
         self.widthConstraint.priority = UILayoutPriority(rawValue: 999)
         NSLayoutConstraint.activate([ratioConstraint, widthConstraint])
     }
     
     //MARK: VisualEffect
     open func rearrangeForVisualEffectView(in vc: UIViewController) {
         self.isVibrancyEffect = true
         self.passwordInputViews.forEach { passwordInputView in
             let label = passwordInputView.label
             label.removeFromSuperview()
             vc.view.addSubview(label)
             label.translatesAutoresizingMaskIntoConstraints = false
             NSLayoutConstraint.addConstraints(fromView: label, toView: passwordInputView, constraintInsets: .zero)
         }
     }
     
     //MARK: Init
     open class func create(withDigit digit: Int) -> PasswordContainerView {
         let bundle = Bundle(for: self)
         let nib = UINib(nibName: "PasswordContainerView", bundle: bundle)
         let view = nib.instantiate(withOwner: self, options: nil).first as! PasswordContainerView
         view.passwordDotView.totalDotCount = digit
         return view
     }
     
     open class func create(in stackView: UIStackView, digit: Int) -> PasswordContainerView {
         let passwordContainerView = create(withDigit: digit)
         stackView.addArrangedSubview(passwordContainerView)
         return passwordContainerView
     }
     
     //MARK: Life Cycle
     open override func awakeFromNib() {
         super.awakeFromNib()
         configureConstraints()
         backgroundColor = .clear
         passwordInputViews.forEach {
             $0.delegate = self
         }
         deleteButton.titleLabel?.adjustsFontSizeToFitWidth = true
         deleteButton.titleLabel?.minimumScaleFactor = 0.5
         touchAuthenticationEnabled = true
         
         var image = touchAuthenticationButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
         
         if #available(iOS 11, *) {
             if touchIDContext.biometryType == .faceID {
                 let bundle = Bundle(for: type(of: self))
                 image = UIImage(named: "faceid", in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
             }
         }
         
         touchAuthenticationButton.setImage(image, for: .normal)
         touchAuthenticationButton.tintColor = tintColor
     }
     
     //MARK: Input Wrong
     open func wrongPassword() {
         passwordDotView.shakeAnimationWithCompletion {
             self.clearInput()
         }
     }
     
     open func clearInput() {
         inputString = ""
     }
     
     //MARK: IBAction
     @IBAction func deleteInputString(_ sender: AnyObject) {
         #if swift(>=3.2)
             guard inputString.count > 0 && !passwordDotView.isFull else {
                 return
             }
             inputString = String(inputString.dropLast())
         #else
             guard inputString.characters.count > 0 && !passwordDotView.isFull else {
             return
             }
             inputString = String(inputString.characters.dropLast())
         #endif
     }
     
     @IBAction func touchAuthenticationAction(_ sender: UIButton) {
         touchAuthentication()
     }
     
     open func touchAuthentication() {
         guard isTouchAuthenticationAvailable else { return }
         touchIDContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: touchAuthenticationReason) { (success, error) in
             DispatchQueue.main.async {
                 if success {
                     self.passwordDotView.inputDotCount = self.passwordDotView.totalDotCount
                     // instantiate LAContext again for avoiding the situation that PasswordContainerView stay in memory when authenticate successfully
                     self.touchIDContext = LAContext()
                 }
                 
                 // delay delegate callback for the user can see passwordDotView input dots filled animation
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                     self.delegate?.touchAuthenticationComplete(self, success: success, error: error)
                 }
             }
         }
     }
 }

 private extension PasswordContainerView {
     func checkInputComplete() {
         #if swift(>=3.2)
             if inputString.count == passwordDotView.totalDotCount {
                 delegate?.passwordInputComplete(self, input: inputString)
             }
         #else
             if inputString.characters.count == passwordDotView.totalDotCount {
             delegate?.passwordInputComplete(self, input: inputString)
             }
         #endif
     }
     
     func configureVibrancyEffect() {
         let whiteColor = UIColor.white
         let clearColor = UIColor.clear
         //delete button title color
         var titleColor: UIColor!
         //dot view stroke color
         var strokeColor: UIColor!
         //dot view fill color
         var fillColor: UIColor!
         //input view background color
         var circleBackgroundColor: UIColor!
         var highlightBackgroundColor: UIColor!
         var borderColor: UIColor!
         //input view text color
         var textColor: UIColor!
         var highlightTextColor: UIColor!
         
         if isVibrancyEffect {
             //delete button
             titleColor = whiteColor
             //dot view
             strokeColor = whiteColor
             fillColor = whiteColor
             //input view
             circleBackgroundColor = clearColor
             highlightBackgroundColor = whiteColor
             borderColor = clearColor
             textColor = whiteColor
             highlightTextColor = whiteColor
         } else {
             //delete button
             titleColor = tintColor
             //dot view
             strokeColor = tintColor
             fillColor = highlightedColor
             //input view
             circleBackgroundColor = whiteColor
             highlightBackgroundColor = highlightedColor
             borderColor = tintColor
             textColor = tintColor
             highlightTextColor = highlightedColor
         }
         
         deleteButton.setTitleColor(titleColor, for: .normal)
         passwordDotView.strokeColor = strokeColor
         passwordDotView.fillColor = fillColor
         touchAuthenticationButton.tintColor = strokeColor
         passwordInputViews.forEach { passwordInputView in
             passwordInputView.circleBackgroundColor = circleBackgroundColor
             passwordInputView.borderColor = borderColor
             passwordInputView.textColor = textColor
             passwordInputView.highlightTextColor = highlightTextColor
             passwordInputView.highlightBackgroundColor = highlightBackgroundColor
             passwordInputView.circleView.layer.borderColor = UIColor.white.cgColor
             //borderWidth as a flag, will recalculate in PasswordInputView.updateUI()
             passwordInputView.isVibrancyEffect = isVibrancyEffect
         }
     }
 }

 extension PasswordContainerView: PasswordInputViewTappedProtocol {
     public func passwordInputView(_ passwordInputView: PasswordInputView, tappedString: String) {
         #if swift(>=3.2)
             guard inputString.count < passwordDotView.totalDotCount else {
                 return
             }
         #else
             guard inputString.characters.count < passwordDotView.totalDotCount else {
             return
             }
         #endif

         inputString += tappedString
     }
 }

 
 
 
 
 
 
 
 
 //
 //  PasswordDotView.swift
 //
 //  Created by rain on 4/21/16.
 //  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
 //

 import UIKit

 @IBDesignable
 open class PasswordDotView: UIView {
     
     //MARK: Property
     @IBInspectable
     open var inputDotCount = 0 {
         didSet {
             let format = Bundle(for: type(of: self)).localizedString(forKey: "PasswordDotViewAccessibilityValue", value: nil, table: nil)
             accessibilityValue = String(format: format, totalDotCount, inputDotCount)
             setNeedsDisplay()
         }
     }
     
     @IBInspectable
     open var totalDotCount = 6 {
         didSet {
             setNeedsDisplay()
         }
     }
     
     @IBInspectable
     open var strokeColor = UIColor.darkGray {
         didSet {
             setNeedsDisplay()
         }
     }
     
     @IBInspectable
     open var fillColor = UIColor.red {
         didSet {
             setNeedsDisplay()
         }
     }

     fileprivate var radius: CGFloat = 6
     fileprivate let spacingRatio: CGFloat = 2
     fileprivate let borderWidthRatio: CGFloat = 1 / 5
     
     fileprivate(set) open var isFull = false
     
     //MARK: Draw
     open override func draw(_ rect: CGRect) {
         super.draw(rect)
         isFull = (inputDotCount == totalDotCount)
         strokeColor.setStroke()
         fillColor.setFill()
         let isOdd = (totalDotCount % 2) != 0
         let positions = getDotPositions(isOdd)
         let borderWidth = radius * borderWidthRatio
         for (index, position) in positions.enumerated() {
             if index < inputDotCount {
                 let pathToFill = UIBezierPath(circleWithCenter: position, radius: (radius + borderWidth / 2), lineWidth: borderWidth)
                 pathToFill.fill()
             } else {
                 let pathToStroke = UIBezierPath(circleWithCenter: position, radius: radius, lineWidth: borderWidth)
                 pathToStroke.stroke()
             }
         }
     }
     
     //MARK: LifeCycle
     open override func awakeFromNib() {
         super.awakeFromNib()
         backgroundColor = UIColor.clear
         isAccessibilityElement = true
         accessibilityLabel = Bundle(for: type(of: self)).localizedString(forKey: "PasswordDotViewAccessibilityLabel", value: nil, table: nil)
     }
     open override func layoutSubviews() {
         super.layoutSubviews()
         updateRadius()
         setNeedsDisplay()
     }
     
     //MARK: Animation
     fileprivate var shakeCount = 0
     fileprivate var direction = false
     open func shakeAnimationWithCompletion(_ completion: @escaping () -> ()) {
         let maxShakeCount = 5
         let centerX = bounds.midX
         let centerY = bounds.midY
         var duration = 0.10
         var moveX: CGFloat = 5
         
         if shakeCount == 0 || shakeCount == maxShakeCount {
             duration *= 0.5
         } else {
             moveX *= 2
         }
         shakeAnimation(withDuration: duration, animations: {
             if !self.direction {
                 self.center = CGPoint(x: centerX + moveX, y: centerY)
             } else {
                 self.center = CGPoint(x: centerX - moveX, y: centerY)
             }
         }) {
             if self.shakeCount >= maxShakeCount {
                 self.shakeAnimation(withDuration: duration, animations: {
                     let realCenterX = self.superview!.bounds.midX
                     self.center = CGPoint(x: realCenterX, y: centerY)
                 }) {
                     self.direction = false
                     self.shakeCount = 0
                     completion()
                 }
             } else {
                 self.shakeCount += 1
                 self.direction = !self.direction
                 self.shakeAnimationWithCompletion(completion)
             }
         }
     }
 }

 private extension PasswordDotView {
     //MARK: Animation
     func shakeAnimation(withDuration duration: TimeInterval, animations: @escaping () -> (), completion: @escaping () -> ()) {
         UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.01, initialSpringVelocity: 0.35, options: .curveEaseInOut, animations: {
             animations()
         }) { _ in
             completion()
         }
     }
     
     //MARK: Update Radius
     func updateRadius() {
         let width = bounds.width
         let height = bounds.height
         radius = height / 2 - height / 2 * borderWidthRatio
         let spacing = radius * spacingRatio
         let count = CGFloat(totalDotCount)
         let spaceCount = count - 1
         if (count * radius * 2 + spaceCount * spacing > width) {
             radius = floor((width / (count + spaceCount)) / 2)
         } else {
             radius = floor(height / 2);
         }
         radius = radius - radius * borderWidthRatio
     }

     //MARK: Dots Layout
     func getDotPositions(_ isOdd: Bool) -> [CGPoint] {
         let centerX = bounds.midX
         let centerY = bounds.midY
         let spacing = radius * spacingRatio
         let middleIndex = isOdd ? (totalDotCount + 1) / 2 : (totalDotCount) / 2
         let offSet = isOdd ? 0 : -(radius + spacing / 2)
         let positions: [CGPoint] = (1...totalDotCount).map { index in
             let i = CGFloat(middleIndex - index)
             let positionX = centerX - (radius * 2 + spacing) * i + offSet
             return CGPoint(x: positionX, y: centerY)
         }
         return positions
     }
 }

 internal extension UIBezierPath {
     convenience init(circleWithCenter center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
         self.init(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2.0 * CGFloat(Double.pi), clockwise: false)
         self.lineWidth = lineWidth
     }
 }

 
 
 
 
 
 
 //
 //  PasswordInputView.swift
 //
 //  Created by rain on 4/21/16.
 //  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
 //

 import UIKit

 public protocol PasswordInputViewTappedProtocol: class {
     func passwordInputView(_ passwordInputView: PasswordInputView, tappedString: String)
 }

 @IBDesignable
 open class PasswordInputView: UIView {
     
     //MARK: Property
     open weak var delegate: PasswordInputViewTappedProtocol?
     
     let circleView = UIView()
     let button = UIButton()
     public let label = UILabel()
     open var labelFont: UIFont?
     fileprivate let fontSizeRatio: CGFloat = 0.7// 46 / 40
     fileprivate let borderWidthRatio: CGFloat = 0.008// 1 / 26
     fileprivate var touchUpFlag = true
     fileprivate(set) open var isAnimating = false
     var isVibrancyEffect = false
     
     @IBInspectable
     open var numberString = "2" {
         didSet {
             label.text = numberString
         }
     }
     
     @IBInspectable
     open var borderColor = UIColor.clear {//darkGray {
         didSet {
             backgroundColor = .clear//borderColor
         }
     }
     
     @IBInspectable
     open var circleBackgroundColor = UIColor.white {
         didSet {
             circleView.backgroundColor = circleBackgroundColor
         }
     }
     
     @IBInspectable
     open var textColor = UIColor.darkGray {
         didSet {
             label.textColor = textColor
         }
     }
     
     @IBInspectable
     open var highlightBackgroundColor = UIColor.orange //UIColor.red
     
     @IBInspectable
     open var highlightTextColor = UIColor.white
     
     //MARK: Life Cycle
     #if TARGET_INTERFACE_BUILDER
     open override func prepareForInterfaceBuilder() {
         super.prepareForInterfaceBuilder()
         configureSubviews()
     }
     #else

     override open func awakeFromNib() {
         super.awakeFromNib()
         configureSubviews()
     }
     #endif

     @objc func touchDown() {
         //delegate callback
         delegate?.passwordInputView(self, tappedString: numberString)
         
         //now touch down, so set touch up flag --> false
         touchUpFlag = false
         touchDownAnimation()
     }
     
     @objc func touchUp() {
         //now touch up, so set touch up flag --> true
         touchUpFlag = true
         
         //only show touch up animation when touch down animation finished
         if !isAnimating {
             touchUpAnimation()
         }
     }
     
     open override func layoutSubviews() {
         super.layoutSubviews()
         updateUI()
     }
     
     fileprivate func getLabelFont() -> UIFont {
         if labelFont != nil {
             return labelFont!
         }
         
         let width = bounds.width
         let height = bounds.height
         let radius = min(width, height) / 2
         return UIFont.systemFont(ofSize: radius * fontSizeRatio,
                                  weight: touchUpFlag ? UIFont.Weight.thin : UIFont.Weight.regular)
     }
     
     fileprivate func updateUI() {
         //prepare calculate
         let width = bounds.width
         let height = bounds.height
         let center = CGPoint(x: width/2, y: height/2)
         let radius = min(width, height) / 2
         let borderWidth = radius * borderWidthRatio
         let circleRadius = radius - borderWidth
         
         //update label
         label.text = numberString
         
         label.font = getLabelFont()
         
         label.textColor = textColor
         
         //update circle view
         circleView.frame = CGRect(x: 0, y: 0, width: 2 * circleRadius, height: 2 * circleRadius)
         circleView.center = center
 //        circleView.layer.cornerRadius = circleRadius
         circleView.layer.cornerRadius = circleView.frame.width / 6
         circleView.backgroundColor = circleBackgroundColor
         //circle view border
         circleView.layer.borderWidth = isVibrancyEffect ? borderWidth : 0
         
         //update mask
 //        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2.0 * CGFloat(Double.pi), clockwise: false)
 //        let maskLayer = CAShapeLayer()
 //        maskLayer.path = path.cgPath
 //        layer.mask = maskLayer
         
         //update color
         backgroundColor = .clear//borderColor
     }
 }

 private extension PasswordInputView {
     //MARK: Awake
     func configureSubviews() {
         addSubview(circleView)

         //configure label
         NSLayoutConstraint.addEqualConstraintsFromSubView(label, toSuperView: self)
         label.textAlignment = .center
         label.isAccessibilityElement = false
         
         //configure button
         NSLayoutConstraint.addEqualConstraintsFromSubView(button, toSuperView: self)
         button.isExclusiveTouch = true
         button.addTarget(self, action: #selector(PasswordInputView.touchDown), for: [.touchDown])
         button.addTarget(self, action: #selector(PasswordInputView.touchUp), for: [.touchUpInside, .touchDragOutside, .touchCancel, .touchDragExit])
         button.accessibilityValue = numberString
     }
     
     //MARK: Animation
     func touchDownAction() {
         label.font = getLabelFont()
         label.textColor = highlightTextColor
         if !self.isVibrancyEffect {
             backgroundColor = highlightBackgroundColor
         }
         circleView.backgroundColor = highlightBackgroundColor
     }
     
     func touchUpAction() {
         label.font = getLabelFont()
         label.textColor = textColor
         backgroundColor = borderColor
         circleView.backgroundColor = circleBackgroundColor
     }
     
     func touchDownAnimation() {
         isAnimating = true
         tappedAnimation(animations: {
             self.touchDownAction()
         }) {
             if self.touchUpFlag {
                 self.touchUpAnimation()
             } else {
                 self.isAnimating = false
             }
         }
     }
     
     func touchUpAnimation() {
         isAnimating = true
         tappedAnimation(animations: {
             self.touchUpAction()
         }) {
             self.isAnimating = false
         }
     }
     
     func tappedAnimation(animations: @escaping () -> (), completion: (() -> ())?) {
         UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: animations) { _ in
             completion?()
         }
     }
 }

 internal extension NSLayoutConstraint {
     class func addConstraints(fromView view: UIView, toView baseView: UIView, constraintInsets insets: UIEdgeInsets) {
         baseView.topAnchor.constraint(equalTo: view.topAnchor, constant: -insets.top)
         let topConstraint = baseView.topAnchor.constraint(equalTo: view.topAnchor, constant: -insets.top)
         let bottomConstraint = baseView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom)
         let leftConstraint = baseView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: -insets.left)
         let rightConstraint = baseView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: insets.right)
         NSLayoutConstraint.activate([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
     }
     
     class func addEqualConstraintsFromSubView(_ subView: UIView, toSuperView superView: UIView) {
         superView.addSubview(subView)
         subView.translatesAutoresizingMaskIntoConstraints = false
         NSLayoutConstraint.addConstraints(fromView: subView, toView: superView, constraintInsets: UIEdgeInsets.zero)
     }
     
     class func addConstraints(fromSubview subview: UIView, toSuperView superView: UIView, constraintInsets insets: UIEdgeInsets) {
         superView.addSubview(subview)
         subview.translatesAutoresizingMaskIntoConstraints = false
         NSLayoutConstraint.addConstraints(fromView: subview, toView: superView, constraintInsets: insets)
     }
 }

 
 
 
 
 
 
 //
 //  PasswordUIValidation.swift
 //
 //  Created by rain on 4/21/16.
 //  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
 //

 open class PasswordUIValidation<T>: PasswordInputCompleteProtocol {
     public typealias Failure    = () -> Void
     public typealias Success    = (T) -> Void
     public typealias Validation = (String) -> T?
     
     open var failure: Failure?
     open var success: Success?
     
     open var validation: Validation?
     
     open var view: PasswordContainerView!
     
     public init(in stackView: UIStackView, width: CGFloat? = nil, digit: Int) {
         view = PasswordContainerView.create(in: stackView, digit: digit)
         view.delegate = self
         guard let width = width else { return }
         view.width = width
     }
     
     open func resetUI() {
         view.clearInput()
     }
     
     //MARK: PasswordInputCompleteProtocol
     open func passwordInputComplete(_ passwordContainerView: PasswordContainerView, input: String) {
         guard let model = self.validation?(input) else {
             passwordContainerView.wrongPassword()
             failure?()
             return
         }
         success?(model)
     }
     
     open func touchAuthenticationComplete(_ passwordContainerView: PasswordContainerView, success: Bool, error: Error?) {}
 }

 
 
 
 
 */
