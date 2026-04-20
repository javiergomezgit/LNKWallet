//
//  PasswordHealthViewController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 4/6/26.
//

import UIKit
import FirebaseAuth

class PasswordHealthViewController: UIViewController {

    // MARK: — State
    private var weakPasswords:   [LNKDataPassword] = []
    private var reusedPasswords: [LNKDataPassword] = []

    private var secretKey    = ""
    private var creationDate = 0

    // MARK: — UI
    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var weakCard:   HealthCardView!
    private var reusedCard: HealthCardView!
    private var leakedCard: HealthCardView!

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary
        setupNavBar()
        setupScrollView()
        setupCards()
        setupLoading()
        setupUser()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAndClassify()
    }

    // MARK: — Setup

    private func setupNavBar() {
        title = "health.title".localized()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .backgroundPrimary
        appearance.shadowColor     = .clear
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .accentBrand
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.axis    = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    private func setupCards() {
        weakCard = HealthCardView(
            icon: "exclamationmark.shield.fill",
            title: "health.weak.title".localized(),
            subtitle: "health.weak.subtitle".localized(),
            accent: UIColor(hex: "#E8614A"),
            comingSoon: false
        )
        reusedCard = HealthCardView(
            icon: "arrow.triangle.2.circlepath",
            title: "health.reused.title".localized(),
            subtitle: "health.reused.subtitle".localized(),
            accent: UIColor(hex: "#C9A84C"),
            comingSoon: false
        )
        leakedCard = HealthCardView(
            icon: "eye.slash.fill",
            title: "health.leaked.title".localized(),
            subtitle: "health.leaked.subtitle".localized(),
            accent: UIColor(hex: "#378ADD"),
            comingSoon: true
        )

        [weakCard, reusedCard, leakedCard].forEach { card in
            contentStack.addArrangedSubview(card!)
            card!.heightAnchor.constraint(equalToConstant: 100).isActive = true
        }

        weakCard.onTap   = { [weak self] in self?.openList(type: .weak) }
        reusedCard.onTap = { [weak self] in self?.openList(type: .reused) }
    }

    private func setupLoading() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .accentBrand
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupUser() {
        guard let user = Auth.auth().currentUser else { return }
        secretKey    = user.uid
        creationDate = Int(user.metadata.creationDate!.timeIntervalSince1970)
    }

    // MARK: — Load & Classify

    private func loadAndClassify() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        loadingIndicator.startAnimating()
        [weakCard, reusedCard, leakedCard].forEach { $0?.setCount(nil) }

        DBManager.shared.getAllEncryptedPasswords(userID: uid) { [weak self] encrypted in
            guard let self = self else { return }

            // Decrypt all
            let decrypted = encrypted.map { self.decrypt($0) }

            // Classify
            self.weakPasswords   = decrypted.filter { self.isWeak($0.password) }
            self.reusedPasswords = self.findReused(decrypted)

            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.weakCard.setCount(self.weakPasswords.count)
                self.reusedCard.setCount(self.reusedPasswords.count)
                self.leakedCard.setCount(nil) // coming soon
            }
        }
    }

    // MARK: — Classification logic

    private func isWeak(_ password: String) -> Bool {
        if password.count < 8 { return true }
        let hasUpper   = password.contains(where: { $0.isUppercase })
        let hasLower   = password.contains(where: { $0.isLowercase })
        let hasNumber  = password.contains(where: { $0.isNumber })
        let hasSymbol  = password.contains(where: { "~!@#$%^&*().,_+=-<>?".contains($0) })
        let score      = [hasUpper, hasLower, hasNumber, hasSymbol].filter { $0 }.count
        return score < 2
    }

    private func findReused(_ passwords: [LNKDataPassword]) -> [LNKDataPassword] {
        var seen:    [String: Int] = [:]
        var reused:  [LNKDataPassword] = []
        for p in passwords {
            seen[p.password, default: 0] += 1
        }
        for p in passwords {
            if seen[p.password]! > 1 { reused.append(p) }
        }
        return reused
    }

    // MARK: — Decryption

    private func decrypt(_ data: LNKDataPassword) -> LNKDataPassword {
        let d = Encryption.shared.encryptDecrypt
        let p = String(creationDate)
        return LNKDataPassword(
            nameData:  d(data.nameData,  p, secretKey, false),
            email:     d(data.email,     p, secretKey, false),
            username:  d(data.username,  p, secretKey, false),
            password:  d(data.password,  p, secretKey, false),
            website:   d(data.website,   p, secretKey, false)
        )
    }

    // MARK: — Navigation

    enum HealthCategory { case weak, reused }

    private func openList(type: HealthCategory) {
        let passwords = type == .weak ? weakPasswords : reusedPasswords
        guard !passwords.isEmpty else {
            showAlert(title: "health.all_clear.title".localized(),
                      message: type == .weak
                        ? "health.no_weak.message".localized()
                        : "health.no_reused.message".localized())
            return
        }

        // Convert LNKDataPassword → LNKData
        let items = passwords.map { LNKData(nameData: $0.nameData, typeData: "type_2") }

        let storyboard = UIStoryboard(name: "Vault", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OpenVaultController") as! OpenVaultController
        vc.preloadedItems = items
        vc.preFilterType  = "type_2"
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "button.ok".localized(), style: .default))
        present(alert, animated: true)
    }
}

// MARK: — HealthCardView

class HealthCardView: UIView {

    var onTap: (() -> Void)?

    private let iconView    = UIImageView()
    private let titleLabel  = UILabel()
    private let subtitleLabel = UILabel()
    private let countLabel  = UILabel()
    private let chevron     = UIImageView()
    private let badge       = UILabel()
    private let spinner     = UIActivityIndicatorView(style: .medium)

    init(icon: String, title: String, subtitle: String, accent: UIColor, comingSoon: Bool) {
        super.init(frame: .zero)

        backgroundColor    = .backgroundSecondary
        layer.cornerRadius = 16
        layer.borderWidth  = 0.5
        layer.borderColor  = UIColor.border.cgColor

        // Icon
        let config = UIImage.SymbolConfiguration(weight: .medium)
        iconView.image       = UIImage(systemName: icon, withConfiguration: config)
        iconView.tintColor   = comingSoon ? .textSecondary : accent
        iconView.contentMode = .scaleAspectFit

        // Title
        titleLabel.text      = title
        titleLabel.font      = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = comingSoon ? .textSecondary : .textPrimary

        // Subtitle
        subtitleLabel.text      = subtitle
        subtitleLabel.font      = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .textSecondary

        // Count
        countLabel.font          = UIFont.systemFont(ofSize: 22, weight: .bold)
        countLabel.textColor     = comingSoon ? .textSecondary : accent
        countLabel.textAlignment = .right

        // Chevron
        chevron.image     = UIImage(systemName: "chevron.right")
        chevron.tintColor = .textSecondary

        // Spinner
        spinner.color   = accent
        spinner.hidesWhenStopped = true

        // Layout
        [iconView, titleLabel, subtitleLabel, countLabel, chevron, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: countLabel.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            countLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            countLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),

            spinner.centerXAnchor.constraint(equalTo: countLabel.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: countLabel.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12)
        ])

        if comingSoon {
            // Coming soon badge
            badge.text              = "health.coming_soon".localized()
            badge.font              = UIFont.systemFont(ofSize: 10, weight: .medium)
            badge.textColor         = .textSecondary
            badge.backgroundColor   = .backgroundPrimary
            badge.layer.cornerRadius = 6
            badge.layer.masksToBounds = true
            badge.textAlignment     = .center
            badge.translatesAutoresizingMaskIntoConstraints = false
            addSubview(badge)
            NSLayoutConstraint.activate([
                badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                badge.centerYAnchor.constraint(equalTo: centerYAnchor),
                badge.heightAnchor.constraint(equalToConstant: 22),
                badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 90)
            ])
            chevron.isHidden     = true
            countLabel.isHidden  = true
            alpha = 0.6
            isUserInteractionEnabled = false
        } else {
            spinner.startAnimating()
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
            addGestureRecognizer(tap)
            isUserInteractionEnabled = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setCount(_ count: Int?) {
        spinner.stopAnimating()
        if let count = count {
            countLabel.text    = "\(count)"
            countLabel.isHidden = false
        }
    }

    @objc private func tapped() { onTap?() }
}

// MARK: — UIColor hex helper

private extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized     = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64  = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8)  / 255
        let b = CGFloat(rgb & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
