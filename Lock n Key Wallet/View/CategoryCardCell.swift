//
//  CategoryCardCell.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 4/1/26.
//

import UIKit

class CategoryCardCell: UICollectionViewCell {
    static let id = "CategoryCardCell"

    private let iconContainer = UIView()
    private let iconView      = UIImageView()
    private let titleLabel    = UILabel()
    private let countLabel    = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 0.5
        contentView.clipsToBounds = true

        iconContainer.layer.cornerRadius = 10
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .textSecondary
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        iconContainer.addSubview(iconView)
        contentView.addSubview(iconContainer)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)

        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconContainer.widthAnchor.constraint(equalToConstant: 36),
            iconContainer.heightAnchor.constraint(equalToConstant: 36),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            countLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        ])
    }

    func configure(with category: VaultCategory, count: Int) {
        titleLabel.text = category.title
        countLabel.text = "\(count) saved"
        iconView.image = category.icon
        iconView.tintColor = category.accent
        iconContainer.backgroundColor = category.accent.withAlphaComponent(0.12)
        contentView.backgroundColor = category.accent.withAlphaComponent(0.06)
        contentView.layer.borderColor = category.accent.withAlphaComponent(0.2).cgColor
    }
}
