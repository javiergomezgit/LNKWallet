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
        
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if user == nil {
                // Only reset if onboarding is complete
                let onboardingComplete = UserDefaults.standard.value(forKey: "firstLaunching") != nil
                if onboardingComplete {
                    SessionManager.resetToSignIn(window: self.window)
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
