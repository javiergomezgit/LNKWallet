//
//  SignInController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/19/21.
//

import UIKit
import AuthenticationServices
import ClockKit
import CryptoKit
import FirebaseAuth
import FirebaseFirestore

class SignInController: UIViewController {
    
    public var completion: ((OAuthCredential) -> (Void))?
    
    @IBOutlet weak var loginViewWithLogo: UIView!
    @IBOutlet weak var loginView: UIStackView!
    fileprivate var currentNonce: String?
    public var deletingAccount = false
    private var signedPreviously = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !deletingAccount {
            setupInitials()
        } else {
            signinApple()
        }
    }
    
    private func setupInitials() {
        if UserDefaults.standard.value(forKey: "auto_lock_time") == nil {
            UserDefaults.standard.set(0, forKey: "auto_lock_time")
            UserDefaults.standard.set(true, forKey: "locked_app")
            UserDefaults.standard.set(true, forKey: "is_new_user")
            UserDefaults.standard.set(3, forKey: "amount_attempts")
            UserDefaults.standard.set(0, forKey: "attempted_failed")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        verifyNetwork()
    }
    
    private func verifyNetwork() {
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            //change to true when finished testing
            if isFirstLaunched() {
                let storyBoard : UIStoryboard = UIStoryboard(name: "Onboarding", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "OnboardingController") as! OnboardingController
                nextViewController.modalPresentationStyle = .fullScreen
                nextViewController.modalTransitionStyle = .crossDissolve
                self.present(nextViewController, animated: true, completion: nil)
            } else {
                DispatchQueue.main.async {
                    _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { timer in
                        self.isSignedIn()
                    })
                }
            }
        }else{
            print("Internet Connection not Available!")
            
            let refreshAlert = UIAlertController(title: "Internet connection", message: "You will need internet for using this app", preferredStyle: UIAlertController.Style.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                exit(0);
            }))
            
            present(refreshAlert, animated: true, completion: nil)
        }
    }
    
    private func isFirstLaunched() -> Bool {
        let isFirstLaunched = UserDefaults.standard.value(forKey: "firstLaunching")
        if isFirstLaunched == nil {
            //Means it's new launched
            UserDefaults.standard.set(false, forKey: "firstLaunching")
            UserDefaults.standard.synchronize()
            return true
        } else {
            return false
        }
    }
    
    private func isSignedIn() {
        let userID = UserDefaults.standard.value(forKey: "firebase_user_id")
        if userID != nil && Auth.auth().currentUser?.uid != nil {
            DBManager.shared.verifyUserExists(userID: Auth.auth().currentUser!.uid) { exists in
                if exists {
                    print("User Exists")
                    DispatchQueue.main.async {
                        print("GOING to MAIN")
                        UserDefaults.standard.set(false, forKey: "is_new_user")
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "MainController")
                        vc.modalPresentationStyle = .fullScreen
                        vc.modalTransitionStyle = .crossDissolve
                        self.show(vc, sender: nil)
                    }
                } else {
                    print("doesnt exists")
                    do {
                        try Auth.auth().signOut()
                        UserDefaults.standard.set(0, forKey: "auto_lock_time")
                        UserDefaults.standard.set(true, forKey: "locked_app")
                        UserDefaults.standard.synchronize()
                        
                        self.signedPreviously = true
                        self.signinApple()
                    } catch {
                        print ("error signin out")
                    }
                }
            }
        } else {
            signinApple()
        }
    }
}

//MARK: Signing Apple
extension SignInController {
    private func signinApple(){
        let appleButton = ASAuthorizationAppleIDButton(type: .continue, style: .black)
        appleButton.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
        loginView.addArrangedSubview(appleButton)
        loginViewWithLogo.isHidden = false
    }
    
    @objc func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
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
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

extension SignInController: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Handle Apple ID credential
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: Login callback received without a nonce.")
            }
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Failed to fetch or serialize identity token: \(appleIDCredential.identityToken?.debugDescription ?? "nil")")
                return
            }

            // Extract Apple ID info
            let userID = appleIDCredential.user // Stable Apple ID identifier
            let email = appleIDCredential.email // Available on first sign-in
            let fullName = appleIDCredential.fullName // Available on first sign-in
            let givenName = fullName?.givenName ?? ""
            let familyName = fullName?.familyName ?? ""
            let displayName = [givenName, familyName].joined(separator: " ").trimmingCharacters(in: .whitespaces)
            let authorizedScopes = appleIDCredential.authorizedScopes // e.g., [.fullName, .email]

            // Debug log
            print("Apple ID: \(userID), Email: \(email ?? "nil"), Name: \(displayName), Scopes: \(authorizedScopes)")

            // Create Firebase credential
            let credential = OAuthProvider.credential(providerID: .apple, idToken: idTokenString, rawNonce: nonce)

            if !deletingAccount {
                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("Firebase sign-in error: \(error.localizedDescription)")
                        return
                    }

                    guard let user = authResult?.user else {
                        print("No Firebase user returned")
                        return
                    }

                    // Save creation timestamp
                    let timeStampSignup = Int(user.metadata.creationDate?.timeIntervalSince1970 ?? 0)
                    UserDefaults.standard.set(timeStampSignup, forKey: "date_creation_user")
                    UserDefaults.standard.set(user.uid, forKey: "firebase_user_id")

                    let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                    UserDefaults.standard.set(isNewUser, forKey: "is_new_user")

                    // Prepare Firestore data
                    let db = Firestore.firestore()
                    var userData: [String: Any] = [
                        "uid": user.uid,
                        "email": user.email ?? email ?? "",
                        "displayName": user.displayName ?? displayName,
                        "dateCreated": timeStampSignup,
                        "photoURL": user.photoURL?.absoluteString ?? ""
                    ]

                    // Add Apple-specific fields
                    if let appleEmail = email {
                        userData["appleEmail"] = appleEmail
                    }
                    if !givenName.isEmpty {
                        userData["givenName"] = givenName
                    }
                    if !familyName.isEmpty {
                        userData["familyName"] = familyName
                    }

                    // Store or update Firestore
                    if isNewUser {
                        UserDefaults.standard.set(true, forKey: "locked_app")
                        db.collection("User").document(user.uid).setData(userData) { err in
                            if let err = err {
                                print("Error writing to Firestore: \(err.localizedDescription)")
                            } else {
                                print("User data saved: \(user.uid)")
                            }
                        }
                    } else {
                        db.collection("User").document(user.uid).updateData(userData) { err in
                            if let err = err {
                                print("Error updating Firestore: \(err.localizedDescription)")
                            } else {
                                print("User data updated: \(user.uid)")
                            }
                        }
                    }

                    // Navigate to main screen
                    DispatchQueue.main.async {
                        print("Navigating to MainController")
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "MainController")
                        vc.modalPresentationStyle = .fullScreen
                        vc.modalTransitionStyle = .crossDissolve
                        self.show(vc, sender: nil)
                    }
                }
            } else {
                // Handle account deletion
                self.completion?(credential)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
}

extension SignInController : ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
