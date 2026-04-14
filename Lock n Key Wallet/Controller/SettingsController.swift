//
//  SettingsController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/19/21.
//

import UIKit
import FirebaseAuth
import SafariServices

class SettingsController: UITableViewController {

    // MARK: — Outlets
    @IBOutlet weak var instantAutoLockSwitch: UISwitch!
    @IBOutlet weak var attemptsStepper: UIStepper!
    @IBOutlet weak var attemptsLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor      = .backgroundPrimary
        tableView.backgroundColor = .backgroundPrimary
        tableView.separatorColor  = .border
        tableView.separatorInset  = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.estimatedSectionFooterHeight = 44
        tableView.estimatedSectionHeaderHeight = 36

        self.title = "Settings"
        
        navigationController?.navigationBar.isHidden = true
        setupCustomHeader()
        setupVersion()
        setupAutoLock()
        setupStepper()
        styleSwitch()
    }

    // MARK: — Setup

    private func setupVersion() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        versionLabel.text      = "Version \(version)"
        versionLabel.textColor = .textSecondary
        versionLabel.font      = UIFont.systemFont(ofSize: 15, weight: .regular)
    }

    private func setupAutoLock() {
        let autoLock = UserDefaults.standard.value(forKey: "instant_auto_lock") as? Bool ?? true
        instantAutoLockSwitch.isOn = autoLock
        if UserDefaults.standard.value(forKey: "locked_app") == nil {
            UserDefaults.standard.set(true, forKey: "locked_app")
        }
        if UserDefaults.standard.value(forKey: "instant_auto_lock") == nil {
            UserDefaults.standard.set(true, forKey: "instant_auto_lock")
        }
    }

    private func setupStepper() {
        let saved = UserDefaults.standard.value(forKey: "amount_attempts") as? Int ?? 3
        attemptsStepper.minimumValue = 3
        attemptsStepper.maximumValue = 10
        attemptsStepper.stepValue    = 1
        attemptsStepper.value        = Double(saved)
        attemptsStepper.tintColor    = .accentBrand
        attemptsLabel.text           = "\(saved)"
        attemptsLabel.font           = UIFont.systemFont(ofSize: 17, weight: .semibold)
        attemptsLabel.textColor      = .textPrimary
        attemptsLabel.textAlignment  = .center
        attemptsLabel.minWidth(44)
    }

    private func setupCustomHeader() {
        let container = UIView()
        container.backgroundColor = .backgroundPrimary
        container.translatesAutoresizingMaskIntoConstraints = false

        let supertitle = UILabel()
        supertitle.text      = "LOCK N KEY"
        supertitle.font      = .systemFont(ofSize: 11, weight: .medium)
        supertitle.textColor = .textSecondary
        supertitle.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text      = "Settings"
        title.font      = .systemFont(ofSize: 26, weight: .medium)
        title.textColor = .textPrimary
        title.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(supertitle)
        container.addSubview(title)

        NSLayoutConstraint.activate([
            supertitle.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            supertitle.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

            title.topAnchor.constraint(equalTo: supertitle.bottomAnchor, constant: 4),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            title.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        // Set as table header
        container.setNeedsLayout()
        container.layoutIfNeeded()
        let height = container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        container.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        tableView.tableHeaderView = container
    }
    
    private func styleSwitch() {
        instantAutoLockSwitch.onTintColor = .accentBrand
    }

    // MARK: — Section headers

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titles = ["SECURITY", "ACCOUNT", "INFO"]
        guard section < titles.count else { return nil }

        let container = UIView()
        container.backgroundColor = .backgroundPrimary

        let label = UILabel()
        let attributed = NSMutableAttributedString(string: titles[section])
        attributed.addAttribute(.kern,
                                value: 0.8,
                                range: NSRange(location: 0, length: titles[section].count))
        label.attributedText = attributed
        label.font      = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .accentBrand
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
        // Footer only for SECURITY section — shows the hint text
        if section == 0 {
            let container = UIView()
            container.backgroundColor = .backgroundPrimary
            let label = UILabel()
            label.text          = "Erase all data after the set number of failed passcode attempts."
            label.font          = UIFont.systemFont(ofSize: 12, weight: .light)
            label.textColor     = .textSecondary
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
            ])
            return container
        }
        let footer = UIView()
        footer.backgroundColor = .backgroundPrimary
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? UITableView.automaticDimension : 8
    }

    // MARK: — Actions

    @IBAction func instantAutoLockChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "locked_app")
        UserDefaults.standard.set(sender.isOn, forKey: "instant_auto_lock")
    }

    @IBAction func attemptsStepperChanged(_ sender: UIStepper) {
        let value = Int(sender.value)
        attemptsLabel.text = "\(value)"
        UserDefaults.standard.set(value, forKey: "amount_attempts")
    }

    @IBAction func logoutTapped(_ sender: UIButton) {
        let alert = UIAlertController(
                title: "Sign Out",
                message: "Are you sure you want to sign out?",
                preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                do {
                    UserDefaults.standard.removeObject(forKey: "instant_auto_lock")
                    UserDefaults.standard.removeObject(forKey: "locked_app")
                    UserDefaults.standard.removeObject(forKey: "amount_attempts")
                    try Auth.auth().signOut()
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let signInVC = storyboard.instantiateViewController(identifier: "SignInController")
                    signInVC.modalPresentationStyle = .fullScreen
                    if let window = self.view.window {
                        window.rootViewController = signInVC
                        window.makeKeyAndVisible()
                    }
                } catch {
                    self.showAlert(title: "Error", message: "Could not sign out. Try again.")
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            configureActionSheetPopover(alert, sourceView: sender)
            present(alert, animated: true)
    }
    
    @IBAction func eraseAllTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Delete all data",
            message: "Are you sure you want to delete all your information?",
            preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            guard let uid = Auth.auth().currentUser?.uid else { return }
            DBManager.shared.deleteAllDatas(userID: uid) { [weak self] success in
                guard let self = self, success else { return }
                self.showAlert(title: "Cleared", message: "Your information has been erased.")
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        configureActionSheetPopover(alert, sourceView: sender)
        present(alert, animated: true)
    }

    @IBAction func deleteAccount(_ sender: Any) {
        let alert = UIAlertController(
            title: "Delete account",
            message: "Are you sure you want to delete your account? This cannot be undone.",
            preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            let user = Auth.auth().currentUser
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "SignInController") as! SignInController
            vc.deletingAccount = true
            vc.modalPresentationStyle = .fullScreen
            vc.completion = { credential in
                user?.reauthenticate(with: credential) { _, error in
                    guard error == nil else { return }
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    DBManager.shared.deleteAccount(userID: uid) { success in
                        guard success else { return }
                        DispatchQueue.main.async {
                            try? Auth.auth().signOut()
                            let signInVC = storyboard.instantiateViewController(identifier: "SignInController")
                            signInVC.modalPresentationStyle = .fullScreen
                            if let window = self.view.window {
                                window.rootViewController = signInVC
                                window.makeKeyAndVisible()
                            }
                        }
                    }
                }
            }
            self.present(vc, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        configureActionSheetPopover(alert, sourceView: sender as? UIView)
        present(alert, animated: true)
    }

    @IBAction func privacyTapped(_ sender: UIButton) {
        openURL("https://jdevit.com/#/apps/lnk-wallet/legal")
    }

    @IBAction func contactTapped(_ sender: UIButton) {
        openURL("https://jdevit.com/#/contact")
    }

    // MARK: — Helpers

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true)
    }

    private func configureActionSheetPopover(_ alert: UIAlertController, sourceView: UIView?) {
        guard let popover = alert.popoverPresentationController else { return }
        popover.sourceView = sourceView ?? view
        popover.sourceRect = sourceView?.bounds ?? CGRect(x: view.bounds.midX,
                                                          y: view.bounds.midY,
                                                          width: 1, height: 1)
        popover.permittedArrowDirections = sourceView == nil ? [] : .any
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

// MARK: — UILabel min width helper

private extension UILabel {
    func minWidth(_ width: CGFloat) {
        let constraint = NSLayoutConstraint(
            item: self, attribute: .width,
            relatedBy: .greaterThanOrEqual,
            toItem: nil, attribute: .notAnAttribute,
            multiplier: 1, constant: width)
        addConstraint(constraint)
    }
}
