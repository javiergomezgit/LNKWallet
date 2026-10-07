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
    private var privacyCover: UIView?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Recording, mirroring or AirPlay starting or stopping while the app is open
        windowScene.registerForTraitChanges([UITraitSceneCaptureState.self]) { [weak self] (_: UIWindowScene, _: UITraitCollection) in
            self?.updatePrivacyCover()
        }
        updatePrivacyCover()

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

    func sceneDidBecomeActive(_ scene: UIScene) {
        updatePrivacyCover()
    }

    // Before iOS takes the app-switcher snapshot
    func sceneWillResignActive(_ scene: UIScene) {
        showPrivacyCover(capturing: false)
    }

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

    // MARK: — Privacy cover

    private var isScreenCaptured: Bool {
        window?.windowScene?.traitCollection.sceneCaptureState == .active
    }

    // Covered while the screen is recorded, mirrored or on AirPlay; uncovered otherwise
    private func updatePrivacyCover() {
        if isScreenCaptured {
            showPrivacyCover(capturing: true)
        } else if window?.windowScene?.activationState == .foregroundActive {
            hidePrivacyCover()
        }
    }

    // Hides the vault behind the logo. While capturing, also says why the app is hidden
    private func showPrivacyCover(capturing: Bool) {
        guard let window = window else { return }
        privacyCover?.removeFromSuperview()

        let cover = UIView(frame: window.bounds)
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cover.backgroundColor  = .backgroundPrimary

        let logo = UIImageView(image: UIImage(named: "LogoIcon"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false

        let message = UILabel()
        message.text          = capturing ? "privacy.capture.message".localized() : nil
        message.font          = .systemFont(ofSize: 15, weight: .regular)
        message.textColor     = .textSecondary
        message.textAlignment = .center
        message.numberOfLines = 0
        message.translatesAutoresizingMaskIntoConstraints = false

        cover.addSubview(logo)
        cover.addSubview(message)
        NSLayoutConstraint.activate([
            logo.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: cover.centerYAnchor, constant: -40),
            logo.widthAnchor.constraint(equalToConstant: 120),
            logo.heightAnchor.constraint(equalToConstant: 120),
            message.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 24),
            message.leadingAnchor.constraint(equalTo: cover.leadingAnchor, constant: 32),
            message.trailingAnchor.constraint(equalTo: cover.trailingAnchor, constant: -32)
        ])

        window.addSubview(cover)
        privacyCover = cover
    }

    private func hidePrivacyCover() {
        privacyCover?.removeFromSuperview()
        privacyCover = nil
    }
}
