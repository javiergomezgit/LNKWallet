//
//  SceneDelegate.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/19/21.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        // Wait for the sign-in to reach the shared keychain, or the first callback can be a
        // transient nil that sends a signed-in user back to the sign-in screen
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.whenAuthReady { [weak self] in
            guard let self = self else { return }
            self.authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                guard let self = self else { return }
                if user == nil {
                    // Signed out or account deleted: LNK AutoFill must stop offering this vault
                    AutoFillSync.clear()
                    // Only reset if onboarding is complete
                    let onboardingComplete = UserDefaults.standard.value(forKey: "firstLaunching") != nil
                    if onboardingComplete {
                        SessionManager.resetToSignIn(window: self.window)
                    }
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if let authStateHandle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Picks up items added or removed on another device while the app was in the background
        if Auth.auth().currentUser != nil {
            AutoFillSync.refresh()
        }

        let isLocked = UserDefaults.standard.bool(forKey: "locked_app")
        guard isLocked, Auth.auth().currentUser != nil else { return }

        DispatchQueue.main.async {
            guard let rootVC = self.window?.rootViewController else { return }
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            guard !(topVC is MasterPasswordController) else { return }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "MasterPasswordController") as! MasterPasswordController
            vc.setPassword            = false
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle   = .crossDissolve
            topVC.present(vc, animated: false)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        let autoLock = UserDefaults.standard.bool(forKey: "instant_auto_lock")
        if autoLock {
            UserDefaults.standard.set(true, forKey: "locked_app")
        }
    }
}
