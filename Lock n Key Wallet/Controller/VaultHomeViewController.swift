//
//  VaultHomeViewController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 4/1/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class VaultHomeViewController: UIViewController {

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var allDatas: [LNKData] = []

    private var counts: [String: Int] = [
        "type_2": 0,  // Passwords
        "type_1": 0,  // Cards
        "type_4": 0,  // Images
        "type_3": 0   // Notes
    ]

    // MARK: - UI Elements
    private let greetingLabel    = UILabel()
    private let addButton        = UIButton(type: .system)
    private let searchBar        = UISearchBar()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private let recentLabel      = UILabel()
    private let recentTableView  = UITableView()
    private var recentItems: [LNKData] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let openVaultTabTitle = "vault.open".localized()
        navigationController?.tabBarItem.title = openVaultTabTitle
        tabBarItem.title = openVaultTabTitle
        setupUI()
        setupCollectionView()
        setupRecentTableView()
        setupAddButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        fetchData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - Data
    private func fetchData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Fetch all for counts
        db.collection("User").document(uid)
            .collection("secret_datas")
            .getDocuments { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                var all: [LNKData] = []
                self.counts = ["type_2": 0, "type_1": 0, "type_4": 0, "type_3": 0]

                for doc in docs {
                    let name = doc.documentID
                    let type = doc.get("key0") as? String ?? ""
                    let item = LNKData(nameData: name, typeData: type)
                    all.append(item)
                    self.counts[type, default: 0] += 1
                }

                self.allDatas = all
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }

        // Fetch recent by lastAccessed
        db.collection("User").document(uid)
            .collection("secret_datas")
            .order(by: "lastAccessed", descending: true)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                self.recentItems = docs.compactMap { doc in
                    let name = doc.documentID
                    guard let type = doc.get("key0") as? String else { return nil }
                    return LNKData(nameData: name, typeData: type)
                }

                DispatchQueue.main.async {
                    self.recentTableView.reloadData()
                    self.recentLabel.isHidden = self.recentItems.isEmpty
                }
            }
    }

    // MARK: - Navigation
    private func navigateToCategory(_ typeData: String) {
        let storyboard = UIStoryboard(name: "Vault", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OpenVaultController") as! OpenVaultController
        vc.preFilterType = typeData
        navigationController?.pushViewController(vc, animated: true)
    }

    private func navigateToAdd(_ identifier: String) {
        let storyboard = UIStoryboard(name: "Vault", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: identifier)
        self.present(vc, animated: true)
    }

    // MARK: - Add Button Menu
    private func setupAddButton() {
        let passwordItem = UIAction(title: "menu.password".localized(), image: UIImage(systemName: "person.badge.key.fill")) { _ in
            self.navigateToAdd("NavDataPasswordController")
        }
        let creditCardItem = UIAction(title: "menu.credit_card".localized(), image: UIImage(systemName: "creditcard.fill")) { _ in
            self.navigateToAdd("NavDataCreditCardController")
        }
        let noteItem = UIAction(title: "menu.secure_note".localized(), image: UIImage(systemName: "lock.rectangle.fill")) { _ in
            self.navigateToAdd("NavDataSecureNoteController")
        }
        let imageItem = UIAction(title: "menu.image".localized(), image: UIImage(systemName: "photo.fill")) { _ in
            self.navigateToAdd("NavDataImageController")
        }
        let menu = UIMenu(title: "menu.store_info".localized(), options: .displayInline, children: [passwordItem, creditCardItem, imageItem, noteItem])
        addButton.menu = menu
        addButton.showsMenuAsPrimaryAction = true
    }
}

// MARK: - UI Setup
extension VaultHomeViewController {

    private func setupUI() {
        view.backgroundColor = .backgroundPrimary

        // Greeting
        greetingLabel.text = "vault.greeting".localized()
        greetingLabel.font = .systemFont(ofSize: 26, weight: .medium)
        greetingLabel.textColor = .textPrimary
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "vault.app_name".localized()
        subtitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.textColor = .textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Add button
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .accentBrand
        addButton.backgroundColor = .backgroundSecondary
        addButton.layer.cornerRadius = 18
        addButton.layer.borderWidth = 0.5
        addButton.layer.borderColor = UIColor.border.cgColor
        addButton.translatesAutoresizingMaskIntoConstraints = false

        // Search bar
        let searchBar = UISearchBar()
        searchBar.placeholder = "vault.search.placeholder".localized()
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.searchTextField.backgroundColor = .backgroundSecondary
        searchBar.searchTextField.layer.cornerRadius = 10
        searchBar.searchTextField.clipsToBounds = true
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self

        // Recent label
        recentLabel.text = "vault.recent".localized()
        recentLabel.font = .systemFont(ofSize: 11, weight: .medium)
        recentLabel.textColor = .textSecondary
        recentLabel.isHidden = true
        recentLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(subtitleLabel)
        view.addSubview(greetingLabel)
        view.addSubview(addButton)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(recentLabel)
        view.addSubview(recentTableView)

        let safeTop = view.safeAreaLayoutGuide.topAnchor

        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: safeTop, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            greetingLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 4),
            greetingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            addButton.centerYAnchor.constraint(equalTo: greetingLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: 36),
            addButton.heightAnchor.constraint(equalToConstant: 36),

            searchBar.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 16),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.heightAnchor.constraint(equalToConstant: cardGridHeight()),

            recentLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 24),
            recentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            recentTableView.topAnchor.constraint(equalTo: recentLabel.bottomAnchor, constant: 8),
            recentTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recentTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            recentTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func cardGridHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let cardWidth = (screenWidth - 40 - 12) / 2
        let cardHeight = cardWidth * 0.65
        return (cardHeight * 2) + 12
    }

    private func setupCollectionView() {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let cardWidth = (UIScreen.main.bounds.width - 40 - 12) / 2
        layout.itemSize = CGSize(width: cardWidth, height: cardWidth * 0.65)

        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(CategoryCardCell.self, forCellWithReuseIdentifier: CategoryCardCell.id)
    }

    private func setupRecentTableView() {
        recentTableView.backgroundColor = .clear
        recentTableView.separatorColor = .border
        recentTableView.separatorInset = UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 0)
        recentTableView.delegate = self
        recentTableView.dataSource = self
        recentTableView.isScrollEnabled = false
        recentTableView.translatesAutoresizingMaskIntoConstraints = false
        recentTableView.register(RecentItemCell.self, forCellReuseIdentifier: RecentItemCell.id)
        recentTableView.rowHeight = 56
    }
}

// MARK: - CollectionView
extension VaultHomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return VaultCategory.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCardCell.id, for: indexPath) as! CategoryCardCell
        let category = VaultCategory.allCases[indexPath.item]
        let count = counts[category.typeKey] ?? 0
        cell.configure(with: category, count: count)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = VaultCategory.allCases[indexPath.item]
        navigateToCategory(category.typeKey)
    }
}

// MARK: - TableView
extension VaultHomeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentItemCell.id, for: indexPath) as! RecentItemCell
        cell.configure(with: recentItems[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = recentItems[indexPath.row]
        navigateToCategory(item.typeData)
    }
}

// MARK: - SearchBar
extension VaultHomeViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let storyboard = UIStoryboard(name: "Vault", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OpenVaultController") as! OpenVaultController
        vc.preFilterType = nil  // show all, search active
        navigationController?.pushViewController(vc, animated: true)
        return false
    }
}
