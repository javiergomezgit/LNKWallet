//
//  ConfigurationViewController.swift
//  LNK AutoFill
//
//  Created by Javier Gomez on 9/22/26.
//

import UIKit

// Shown once when the user turns LNK Wallet on in Settings › General › AutoFill & Passwords.
// Explains what happens next, and asks for one app launch when the offline copy isn't there yet.
final class ConfigurationViewController: UIViewController {

    // MARK: — State
    var onDone: (() -> Void)?

    private let passwordsReady: Bool

    private let logoView   = UIImageView(image: UIImage(named: "LogoIcon"))
    private let titleLabel = UILabel()
    private let bodyLabel  = UILabel()
    private let doneButton = UIButton(type: .system)

    // MARK: — Lifecycle

    init(passwordsReady: Bool) {
        self.passwordsReady = passwordsReady
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary
        setupLabels()
        setupButton()
        setupLayout()
    }

    // MARK: — Setup

    private func setupLabels() {
        logoView.contentMode = .scaleAspectFit

        titleLabel.text          = "autofill.setup.title".localized()
        titleLabel.font          = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor     = .textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        bodyLabel.text          = passwordsReady ? "autofill.setup.ready".localized() : "autofill.setup.open_app".localized()
        bodyLabel.font          = UIFont.systemFont(ofSize: 15, weight: .regular)
        bodyLabel.textColor     = .textSecondary
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
    }

    private func setupButton() {
        stylePrimaryButton(doneButton, title: "autofill.setup.done".localized())
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [logoView, titleLabel, bodyLabel])
        stack.axis    = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(8, after: logoView)

        [stack, doneButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            logoView.heightAnchor.constraint(equalToConstant: 72),

            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    // MARK: — Actions

    @objc private func doneTapped() {
        onDone?()
    }
}
