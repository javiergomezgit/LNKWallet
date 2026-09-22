//
//  CredentialProviderViewController.swift
//  LNK AutoFill
//
//  Created by Javier Gomez on 9/22/26.
//

import AuthenticationServices
import FirebaseCore
import FirebaseAuth

// Entry point iOS calls for every AutoFill request. Nothing is decrypted or shown until the unlock
// gate passes; passwords come from the obfuscated offline copy the app writes to the App Group.
class CredentialProviderViewController: ASCredentialProviderViewController {

    // MARK: — Entry points

    // Tap a password field › key icon › LNK Wallet
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        requireUnlock { [weak self] items in
            self?.showList(items: items, serviceIdentifiers: serviceIdentifiers)
        }
    }

    // Never hand over a password without the user in front of our UI. Both overrides are required:
    // the base class's default identity and request variants call each other forever.
    override func provideCredentialWithoutUserInteraction(for credentialRequest: ASCredentialRequest) {
        cancel(with: .userInteractionRequired)
    }

    // Tap a QuickType suggestion: fill that exact item after unlock, no list
    override func prepareInterfaceToProvideCredential(for credentialRequest: ASCredentialRequest) {
        let identity = credentialRequest.credentialIdentity
        requireUnlock { [weak self] items in
            guard let self = self else { return }
            if let recordID = identity.recordIdentifier,
               let item = items?.first(where: { $0.documentID == recordID }) {
                self.complete(with: item)
            } else {
                // Deleted since the suggestion was made: drop it and let the user pick
                self.removeStaleSuggestion(identity)
                self.showList(items: items, serviceIdentifiers: [identity.serviceIdentifier])
            }
        }
    }

    // Settings › AutoFill & Passwords › LNK Wallet turned on. AutoFill 10 adds a screen here.
    override func prepareInterfaceForExtensionConfiguration() {
        extensionContext.completeExtensionConfigurationRequest()
    }

    // MARK: — Unlock

    // Covers the screen with the unlock gate. Only after Face ID or the master password are the
    // offline records decrypted and handed to the action (nil when the app hasn't written them yet).
    private func requireUnlock(then action: @escaping ([FillItem]?) -> Void) {
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        try? Auth.auth().useUserAccessGroup(AppGroup.keychainAccessGroup)
        let user         = Auth.auth().currentUser
        let creationDate = user?.metadata.creationDate.map { Int($0.timeIntervalSince1970) }

        let unlock = UnlockViewController(creationDate: creationDate)
        unlock.onUnlock = { [weak unlock] in
            guard let user = user, let creationDate = creationDate else { return }
            unlock?.willMove(toParent: nil)
            unlock?.view.removeFromSuperview()
            unlock?.removeFromParent()

            let items = AutoFillCache.read(uid: user.uid)?.map {
                FillItem(decrypting: $0, secretKey: user.uid, creationDate: creationDate)
            }
            action(items)
        }
        unlock.onCancel = { [weak self] in
            self?.cancel(with: .userCanceled)
        }
        embed(unlock)
    }

    // MARK: — List

    private func showList(items: [FillItem]?, serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let list = CredentialListViewController(items: items,
                                                serviceIdentifiers: serviceIdentifiers.map { $0.identifier })
        list.onSelect = { [weak self] item in
            self?.complete(with: item)
        }
        list.onCancel = { [weak self] in
            self?.cancel(with: .userCanceled)
        }
        embed(UINavigationController(rootViewController: list))
    }

    // MARK: — Completion

    private func complete(with item: FillItem) {
        let credential = ASPasswordCredential(user: item.user, password: item.password)
        extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
    }

    private func cancel(with code: ASExtensionError.Code) {
        extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: code.rawValue))
    }

    private func removeStaleSuggestion(_ identity: ASCredentialIdentity) {
        ASCredentialIdentityStore.shared.removeCredentialIdentities([identity]) { _, error in
            if let error = error { print("Removing stale AutoFill suggestion failed: \(error)") }
        }
    }

    // MARK: — Containment

    private func embed(_ child: UIViewController) {
        addChild(child)
        child.view.frame            = view.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
}
