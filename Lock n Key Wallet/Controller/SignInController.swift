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
        
//        do {
//            try Auth.auth().signOut()
//            print ("SIGNout Firebase")
//        } catch {
//            print ("error signin out")
//        }
        
        if !deletingAccount {
            setupInitials()
        } else {
            signinApple()
        }
    }
    
    private func setupInitials() {
//        if UserDefaults.standard.value(forKey: "instant_auto_lock_time") == nil {
//            UserDefaults.standard.set(true, forKey: "instant_auto_lock_time")
//            UserDefaults.standard.set(true, forKey: "locked_app")
//            UserDefaults.standard.set(true, forKey: "is_new_user")
//            UserDefaults.standard.set(false, forKey: "found_passcode")
//        }
//        if UserDefaults.standard.value(forKey: "save_offline") == nil {
//            UserDefaults.standard.set(false, forKey: "save_offline")
//        }
//        if UserDefaults.standard.value(forKey: "wrong_passcode") == nil {
//            UserDefaults.standard.set("0", forKey: "wrong_passcode")
//        }
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
//        if !deletingAccount {
//            verifyNetwork()
//        }
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
                print (exists)
                if exists {
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
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let providerID = AuthProviderID.apple
            let credential = OAuthProvider.credential(providerID: providerID,
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
                                                    
            //credential(providerID: AuthProviderID, idToken: String, rawNonce: String, accessToken: String? = nil) -> OAuthCredential`
//            let credential = OAuthProvider.credential(withProviderID: "apple.com",
//                                                      idToken: idTokenString,
//                                                      rawNonce: nonce)
            if !deletingAccount {
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    
                    let timeStampSignup = Int(authResult!.user.metadata.creationDate!.timeIntervalSince1970)
                    UserDefaults.standard.set(timeStampSignup, forKey: "date_creation_user")

                    if error != nil {
                        print(error?.localizedDescription ?? "")
                        return
                    } else {
                        guard let user = authResult?.user else { return }
                        let isNewUser = authResult!.additionalUserInfo!.isNewUser
                                                
                        if isNewUser {
                            UserDefaults.standard.set(true, forKey: "is_new_user")
                            UserDefaults.standard.set(true, forKey: "locked_app")
                            UserDefaults.standard.set(user.uid, forKey: "firebase_user_id")

                            
                            let email = user.email ?? ""
                            let displayName = user.displayName ?? ""
                            let photoURL = user.photoURL?.absoluteString  ?? ""
                            
                            let db = Firestore.firestore()
                            db.collection("User").document(user.uid).setData(["email": email, "displayName": displayName, "uid": user.uid, "dateCreated" : timeStampSignup, "photoURL": photoURL]) { err in
                                if let err = err {
                                    print("Error writing document: \(err)")
                                } else {
                                    print("the user has sign up or is logged in")
                                }
                            }
                        } else {
                            UserDefaults.standard.set(false, forKey: "is_new_user")
                            UserDefaults.standard.set(user.uid, forKey: "firebase_user_id")
                        }
                        
                        DispatchQueue.main.async {
                            print("GOING to MAIN")
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "MainController")
                            vc.modalPresentationStyle = .fullScreen
                            vc.modalTransitionStyle = .crossDissolve
                            self.show(vc, sender: nil)
                        }
                    }
                }
            } else {
                //Deleting account
                self.completion!(credential)
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
