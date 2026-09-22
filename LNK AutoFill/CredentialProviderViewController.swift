//
//  CredentialProviderViewController.swift
//  LNK AutoFill
//
//  Created by Javier Gomez on 9/22/26.
//

//  AUTOFILL 02 SPIKE — throwaway. Measures the memory cost of Firebase Auth + Firestore
//  inside the extension. Replaced by the real fill UI in AutoFill 07.

import AuthenticationServices
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import os

class CredentialProviderViewController: ASCredentialProviderViewController {

    // MARK: — State
    private let logger   = Logger(subsystem: "com.jdev.Lock-n-Key-Wallet.LNK-AutoFill", category: "spike")
    private let textView = UITextView()
    private var report   = ""
    private var started  = false

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupReportView()
        record("1. extension loaded")
    }

    // MARK: — Entry points

    // Settings › General › AutoFill & Passwords › toggle LNK Wallet on
    override func prepareInterfaceForExtensionConfiguration() {
        runSpike(trigger: "configuration")
    }

    // Tap a password field › key icon › LNK Wallet
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        runSpike(trigger: "credential list (\(serviceIdentifiers.map { $0.identifier }.joined(separator: ", ")))")
    }

    // MARK: — Setup

    private func setupReportView() {
        view.subviews.forEach { $0.isHidden = true }

        textView.isEditable      = false
        textView.font            = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor       = .label
        textView.backgroundColor = .systemBackground
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(cancel(_:)), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.topAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: — Spike

    private func runSpike(trigger: String) {
        guard !started else { return }
        started = true
        record("   trigger: \(trigger)")

        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        record("2. FirebaseApp.configure()")

        do {
            try Auth.auth().useUserAccessGroup(AppGroup.keychainAccessGroup)
        } catch {
            record("   shared keychain error: \(error.localizedDescription)")
        }
        let user = Auth.auth().currentUser
        record("3. Auth ready (signed in: \(user != nil))")
        // AutoFill 04 check: the key material comes straight from the shared session
        if let user = user {
            let hasCreationDate = user.metadata.creationDate != nil
            record("   uid: \(user.uid.prefix(4))… · creation date: \(hasCreationDate ? "yes" : "MISSING")")
        }

        // In-memory cache: the extension has no use for Firestore's on-disk cache
        let settings           = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        let db                 = Firestore.firestore()
        db.settings            = settings
        record("4. Firestore ready")

        // Read-only server round trip: loads the full network stack without writing anything.
        // Rejected by security rules while the extension has no shared sign-in (AutoFill 04).
        db.collection("User").document(user?.uid ?? "autofill-spike-probe")
            .getDocument(source: .server) { [weak self] _, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.record("5. server round trip (\(error.map { "error: \($0.localizedDescription)" } ?? "ok"))")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.record("6. settled +2s")
                        self.record("\nDone. Screenshot this and tap Done.")
                    }
                }
            }
    }

    // MARK: — Measurement

    private func record(_ step: String) {
        let used      = Self.footprintMB()
        let available = Double(os_proc_available_memory()) / 1_048_576
        let line      = step.hasPrefix(" ") || step.hasPrefix("\n")
            ? step
            : String(format: "%@\n   used %.1f MB · free %.1f MB · limit ≈ %.0f MB", step, used, available, used + available)

        report += line + "\n"
        textView.text = report
        logger.log("\(line, privacy: .public)")
    }

    // Same number Xcode's memory gauge and the jetsam limit use
    private static func footprintMB() -> Double {
        var info  = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
    }

    // MARK: — Actions

    @IBAction func cancel(_ sender: AnyObject?) {
        self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
    }

    @IBAction func passwordSelected(_ sender: AnyObject?) {
        cancel(sender)
    }
}
