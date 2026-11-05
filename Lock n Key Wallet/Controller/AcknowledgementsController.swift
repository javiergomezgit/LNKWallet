//
//  AcknowledgementsController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/4/26.
//

import UIKit

// Shows the licenses of the open-source packages the app ships, from Acknowledgements.txt.
// Regenerate that file whenever a Swift package is added, removed or updated.
class AcknowledgementsController: UIViewController {

    // MARK: — State
    private let textView = UITextView()

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary

        setupNavBar()
        setupTextView()
    }

    // MARK: — Setup

    private func setupNavBar() {
        title = "settings.menu.acknowledgements".localized()

        let closeBtn = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(closeTapped))
        closeBtn.tintColor = .textSecondary
        navigationItem.leftBarButtonItem = closeBtn
    }

    private func setupTextView() {
        textView.isEditable         = false
        textView.backgroundColor    = .backgroundPrimary
        textView.textColor          = .textSecondary
        textView.font               = .preferredFont(forTextStyle: .footnote)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 24, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false

        if let url = Bundle.main.url(forResource: "Acknowledgements", withExtension: "txt") {
            textView.text = try? String(contentsOf: url, encoding: .utf8)
        }

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: — Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
