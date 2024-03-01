//
//  SettingsController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/19/21.
//

import UIKit
import SafariServices
import FirebaseAuth

class SettingsController: UITableViewController {
    
    @IBOutlet weak var attemptsTextField: UITextField!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var instantAutoLockSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        versionLabel.text = "Version \(appVersion)"
        
        self.hideKeyboardWhenTappedAround()
        loadAttempts()
        
        if let autoLock = UserDefaults.standard.value(forKey: "instant_auto_lock") as? Bool {
            if let lockedApp = UserDefaults.standard.value(forKey: "locked_app") as? Bool {
                UserDefaults.standard.set(lockedApp, forKey: "locked_app")
            } else {
                UserDefaults.standard.set(true, forKey: "locked_app")
            }
            instantAutoLockSwitch.isOn = autoLock
        } else {
            UserDefaults.standard.set(true, forKey: "instant_auto_lock")
            UserDefaults.standard.set(true, forKey: "locked_app")
            instantAutoLockSwitch.isOn = true
        }
    }
    
    @IBAction func attemptsChanged(_ sender: UITextField) {
        if let attempts = Int(attemptsTextField.text!) {
            UserDefaults.standard.set(attempts, forKey: "amount_attempts")
        } else {
            attemptsTextField.text! = "3"
            UserDefaults.standard.set(3, forKey: "amount_attempts")
        }
       
    }
    
    @IBAction func instantAutoLockChanged(_ sender: UISwitch) {
        print (instantAutoLockSwitch.isOn)
        UserDefaults.standard.set(instantAutoLockSwitch.isOn, forKey: "locked_app")
        UserDefaults.standard.set(instantAutoLockSwitch.isOn, forKey: "instant_auto_lock")
    }
    
    
    func loadAttempts(){
        if let attempts = UserDefaults.standard.value(forKey: "amount_attempts") as? Int {
            attemptsTextField.text! = String(attempts)
        } else {
            attemptsTextField.text! = "3"
            UserDefaults.standard.set(3, forKey: "amount_attempts")
        }

    }
    
    //Reset all
    @IBAction func eraseAllTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Delete all data", message: "Are you sure you want to delete all your information?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            
            DBManager.shared.deleteAllDatas(userID: Auth.auth().currentUser!.uid) { success in
                if success {
                    let alertController = UIAlertController(title: "Cleared", message: "Your information has been erased", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(action)
                    self.present(alertController, animated: true)
                }
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
        
    }
    
    @IBAction func deleteAccount(_ sender: Any) {
        let alert = UIAlertController(title: "Delete account", message: "Are you sure you want to delete your account?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                        
            //Prompt the user to re-provide their sign-in credentials
            let user = Auth.auth().currentUser

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "SignInController") as! SignInController
            vc.deletingAccount = true
            vc.modalPresentationStyle = .fullScreen
            vc.completion = { credential in
                user?.reauthenticate(with: credential, completion: { result, error in
                    print (result as Any)
                    if error == nil {
                        DBManager.shared.deleteAccount(userID: Auth.auth().currentUser!.uid) { success in
                            if success {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        exit(0)
                                    }
                                }
                            }
                        }
                    }
                })
            }
            self.present(vc, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    
    @IBAction func privacyTapped(_ sender: UIButton) {
        if let url = URL(string: "https://www.locknkey.app/privacy-policy-lock-n-key-wallet/") {
            let svc = SFSafariViewController(url: url)
            self.present(svc, animated: true, completion: nil)
        }
    }
    
    @IBAction func contactTapped(_ sender: UIButton) {
        if let url = URL(string: "https://www.locknkey.app/contact/") {
            let svc = SFSafariViewController(url: url)
            self.present(svc, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 2 ? CGFloat.leastNormalMagnitude : 32
    }
    
//    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 25.0
//    }
    
    
//    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        guard let header = view as? UITableViewHeaderFooterView else { return }
//        header.textLabel?.textColor = UIColor.red
//        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
//        header.textLabel?.frame = header.bounds
//        header.textLabel?.textAlignment = .center
//    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .light)
//        header.textLabel?.frame = header.bounds
//        header.textLabel?.textAlignment = .justified
    }
}


