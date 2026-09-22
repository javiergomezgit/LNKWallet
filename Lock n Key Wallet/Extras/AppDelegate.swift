//
//  AppDelegate.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/19/21.
//

import UIKit
import CoreData
import Firebase
import FirebaseAuth
import AuthenticationServices

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()

        configureTabBar()

        let isFirstRun = !UserDefaults.standard.bool(forKey: "app_has_launched_before")
        if isFirstRun {
            // Clear any stale Firebase auth from previous install, in both keychain groups
            try? Auth.auth().signOut()
            if (try? Auth.auth().useUserAccessGroup(AppGroup.keychainAccessGroup)) != nil {
                try? Auth.auth().signOut()
            }
            // Clear all UserDefaults
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.set(true, forKey: "app_has_launched_before")
            UserDefaults.standard.synchronize()
        }

        shareAuthWithAutoFill { [weak self] in
            self?.markAuthReady()
        }

        return true
    }

    // MARK: — Shared sign-in

    private var isAuthReady       = false
    private var authReadyHandlers = [() -> Void]()

    // Runs the handler once the Firebase session is in its final keychain group. Anything that
    // reacts to a nil currentUser must wait for this, or it sees the user mid-migration.
    func whenAuthReady(_ handler: @escaping () -> Void) {
        if isAuthReady {
            handler()
        } else {
            authReadyHandlers.append(handler)
        }
    }

    private func markAuthReady() {
        DispatchQueue.main.async {
            self.isAuthReady = true
            self.authReadyHandlers.forEach { $0() }
            self.authReadyHandlers.removeAll()
        }
    }

    // Keeps the Firebase session in the keychain group LNK AutoFill can read. Only does real work
    // once per device, for users signed in before the extension existed: their session sits in the
    // app's default group and is copied over, then the old copy is removed so a later sign-out
    // can't bring it back. Never run this in the extension.
    private func shareAuthWithAutoFill(completion: @escaping () -> Void) {
        let legacyUser = Auth.auth().currentUser

        do {
            try Auth.auth().useUserAccessGroup(AppGroup.keychainAccessGroup)
        } catch {
            // Stay on the default group: the app keeps working, AutoFill can't sign in
            print("Shared keychain unavailable: \(error)")
            completion()
            return
        }

        guard let legacyUser = legacyUser else {
            completion()
            return
        }

        if Auth.auth().currentUser != nil {
            removeLegacySession()
            completion()
            return
        }

        Auth.auth().updateCurrentUser(legacyUser) { [weak self] error in
            if let error = error {
                // Fall back to the old copy so the user stays signed in; retried next launch
                print("Moving sign-in to the shared keychain failed: \(error)")
                try? Auth.auth().useUserAccessGroup(nil)
            } else {
                self?.removeLegacySession()
            }
            completion()
        }
    }

    private func removeLegacySession() {
        do {
            try Auth.auth().useUserAccessGroup(nil)
            try Auth.auth().signOut()
            try Auth.auth().useUserAccessGroup(AppGroup.keychainAccessGroup)
        } catch {
            print("Removing the old sign-in copy failed: \(error)")
        }
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .backgroundChrome
        appearance.shadowColor = .border

        // Kill the pill
        appearance.selectionIndicatorTintColor = .clear
        appearance.selectionIndicatorImage = UIImage()

        // Active
        appearance.stackedLayoutAppearance.selected.iconColor = .accentBrand
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.accentBrand,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        // Inactive
        appearance.stackedLayoutAppearance.normal.iconColor = .textSecondary
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.textSecondary,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().tintColor = .accentBrand
        UITabBar.appearance().unselectedItemTintColor = .textSecondary

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
//        UITabBar.appearance().tintColor = .accentBrand
//        UITabBar.appearance().unselectedItemTintColor = .textSecondary
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "Lock_n_Key_Wallet")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

