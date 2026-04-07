//
//  ToolsViewController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 4/6/26.
//

import UIKit
import SafariServices

class ToolsViewController: UIViewController {

    // MARK: — UI Elements

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var healthCardView: HealthCardView?
    
    private let pageTitleLabel = UILabel()
    private let pageSupertitleLabel = UILabel()

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary
        setupNavBar()
        setupScrollView()
        setupToolCards()
        setupPromoSection()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    // MARK: — Nav Bar

    private func setupNavBar() {
        navigationController?.navigationBar.isHidden = true

        pageSupertitleLabel.text      = "LOCK N KEY"
        pageSupertitleLabel.font      = .systemFont(ofSize: 11, weight: .medium)
        pageSupertitleLabel.textColor = .textSecondary
        pageSupertitleLabel.translatesAutoresizingMaskIntoConstraints = false

        pageTitleLabel.text      = "Tools"
        pageTitleLabel.font      = .systemFont(ofSize: 26, weight: .medium)
        pageTitleLabel.textColor = .textPrimary
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(pageSupertitleLabel)
        view.addSubview(pageTitleLabel)

        NSLayoutConstraint.activate([
            pageSupertitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            pageSupertitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pageTitleLabel.topAnchor.constraint(equalTo: pageSupertitleLabel.bottomAnchor, constant: 4),
            pageTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])
    }

    // MARK: — Scroll + Stack

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.axis    = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: pageTitleLabel.bottomAnchor, constant: 16),
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

    // MARK: — Tool Cards

    private func setupToolCards() {
        let cardRow = UIStackView()
        cardRow.axis         = .horizontal
        cardRow.spacing      = 16
        cardRow.distribution = .fillEqually

        // Generator — plain card
        let generatorCard = makeToolCard(
            icon: "key.fill",
            title: "Password\nGenerator",
            accent: .accentBrand,
            comingSoon: false,
            action: #selector(generatorTapped)
        )

        // Health — plain card
        let healthCard = makeToolCard(
            icon: "heart.text.square.fill",
            title: "Password\nHealth",
            accent: .accentBrand,
            comingSoon: false,
            action: #selector(healthTapped)
        )

        cardRow.addArrangedSubview(generatorCard)
        cardRow.addArrangedSubview(healthCard)
        generatorCard.heightAnchor.constraint(equalToConstant: 160).isActive = true
        healthCard.heightAnchor.constraint(equalToConstant: 160).isActive = true

        contentStack.addArrangedSubview(cardRow)
    }

    @objc private func healthTapped() {
        let vc = PasswordHealthViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func makeToolCard(icon: String,
                               title: String,
                               accent: UIColor,
                               comingSoon: Bool,
                               action: Selector?) -> UIView {
        let card = UIView()
        card.backgroundColor    = .backgroundSecondary
        card.layer.cornerRadius = 16
        card.layer.borderWidth  = 0.5
        card.layer.borderColor  = UIColor.border.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        let iconView = UIImageView()
        let config = UIImage.SymbolConfiguration(weight: .medium)
        iconView.image = UIImage(systemName: icon, withConfiguration: config)
        iconView.tintColor   = comingSoon ? .textSecondary : accent
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        let titleLabel           = UILabel()
        titleLabel.text          = title
        titleLabel.numberOfLines = 2
        titleLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor     = comingSoon ? .textSecondary : .textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconView)
        card.addSubview(titleLabel)

        // Constraints
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        // Coming soon badge
        if comingSoon {
            let badge               = UILabel()
            badge.text              = "Coming soon"
            badge.font              = UIFont.systemFont(ofSize: 10, weight: .medium)
            badge.textColor         = .textSecondary
            badge.backgroundColor   = .backgroundPrimary
            badge.layer.cornerRadius = 6
            badge.layer.masksToBounds = true
            badge.textAlignment     = .center
            badge.translatesAutoresizingMaskIntoConstraints = false
            badge.layoutMargins     = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

            card.addSubview(badge)
            NSLayoutConstraint.activate([
                badge.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
                badge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
                badge.heightAnchor.constraint(equalToConstant: 22),
                badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
            ])
        }

        // Tap gesture
        if let action = action {
            let tap = UITapGestureRecognizer(target: self, action: action)
            card.addGestureRecognizer(tap)
            card.isUserInteractionEnabled = true
        } else {
            card.isUserInteractionEnabled = false
            card.alpha = 0.6
        }

        return card
    }

    // MARK: — Promo Section

    private func setupPromoSection() {
        // Section header
        let header           = UILabel()
        let attributed       = NSMutableAttributedString(string: "TRY OUR OTHER APP")
        attributed.addAttribute(.kern,
                                value: 0.8,
                                range: NSRange(location: 0, length: attributed.length))
        header.attributedText = attributed
        header.font           = UIFont.systemFont(ofSize: 11, weight: .semibold)
        header.textColor      = .accentBrand
        contentStack.addArrangedSubview(header)

        // Promo card
        let promoCard               = UIView()
        promoCard.backgroundColor   = .backgroundSecondary
        promoCard.layer.cornerRadius = 16
        promoCard.layer.borderWidth  = 0.5
        promoCard.layer.borderColor  = UIColor.border.cgColor
        promoCard.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        let iconBg               = UIView()
        iconBg.backgroundColor   = UIColor.accentBrand.withAlphaComponent(0.15)
        iconBg.layer.cornerRadius = 10
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let iconView             = UIImageView()
        let symConfig            = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image           = UIImage(systemName: "message.fill", withConfiguration: symConfig)
        iconView.tintColor       = .accentBrand
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconView)

        // Labels
        let titleLabel           = UILabel()
        titleLabel.text          = "LNK Chats"
        titleLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor     = .textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel        = UILabel()
        subtitleLabel.text       = "Encrypted instant messaging"
        subtitleLabel.font       = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor  = .textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Chevron
        let chevron              = UIImageView()
        chevron.image            = UIImage(systemName: "chevron.right")
        chevron.tintColor        = .textSecondary
        chevron.translatesAutoresizingMaskIntoConstraints = false

        let labelStack           = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStack.axis          = .vertical
        labelStack.spacing       = 3
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        promoCard.addSubview(iconBg)
        promoCard.addSubview(labelStack)
        promoCard.addSubview(chevron)

        NSLayoutConstraint.activate([
            promoCard.heightAnchor.constraint(equalToConstant: 72),

            iconBg.leadingAnchor.constraint(equalTo: promoCard.leadingAnchor, constant: 16),
            iconBg.centerYAnchor.constraint(equalTo: promoCard.centerYAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),

            labelStack.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            labelStack.centerYAnchor.constraint(equalTo: promoCard.centerYAnchor),
            labelStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            chevron.trailingAnchor.constraint(equalTo: promoCard.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: promoCard.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(promoTapped))
        promoCard.addGestureRecognizer(tap)
        promoCard.isUserInteractionEnabled = true

        contentStack.addArrangedSubview(promoCard)
    }

    // MARK: — Actions

    @objc private func generatorTapped() {
        let storyboard = UIStoryboard(name: "Tools", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "GeneratePasswordController")
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func promoTapped() {
        // Try App Store app first, fall back to web
        let appStoreURL = URL(string: "itms-apps://apps.apple.com/app/id1579179734")!
        let webURL      = URL(string: "https://apps.apple.com/app/id1579179734")!
        
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}
