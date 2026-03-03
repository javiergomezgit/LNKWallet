//
//  SessionManager.swift
//  Lock n Key Wallet
//
//  Created by Javier on 3/3/26.
//

import UIKit
import FirebaseAuth

enum SessionManager {
    private static let userDefaultsKeysToClear: [String] = [
        "firebase_user_id",
        "date_creation_user",
        "is_new_user",
        "locked_app",
        "amount_attempts",
        "attempted_failed",
        "auto_lock_time",
        "instant_auto_lock",
        "firstLaunching"
    ]
    
    static func clearStoredUserDefaults() {
        let defaults = UserDefaults.standard
        userDefaultsKeysToClear.forEach { defaults.removeObject(forKey: $0) }
    }
    
    static func resetToSignIn(window: UIWindow?) {
        clearStoredUserDefaults()
        
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let signInVC = storyboard.instantiateViewController(withIdentifier: "SignInController")
            signInVC.modalPresentationStyle = .fullScreen
            
            if let window = window {
                window.rootViewController = signInVC
                window.makeKeyAndVisible()
            } else {
                // Fallback for cases where window isn't available.
                let scene = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
                scene?.rootViewController = signInVC
                scene?.makeKeyAndVisible()
            }
        }
    }
    
    static func forceSignOutAndReset(window: UIWindow?) {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
        resetToSignIn(window: window)
    }
}
