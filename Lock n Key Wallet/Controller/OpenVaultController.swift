//
//  OpenVaultController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/19/21.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class OpenVaultController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Filter
    private let filterScrollView = UIScrollView()
    private let filterStackView  = UIStackView()
    private var filterButtons: [UIButton] = []
    var preloadedItems: [LNKData]? = nil

    private let filterOptions: [(titleKey: String, type: String?)] = [
        ("filter.all", nil),
        ("filter.passwords", "type_2"),
        ("filter.cards", "type_1"),
        ("filter.images", "type_4"),
        ("filter.notes", "type_3")
    ]

    // MARK: - Data
    let refreshControl = UIRefreshControl()
    private var lnkDatas: [LNKData] = []
    private var filteredDatas: [LNKData] = []
    private var searchController = UISearchController()
    var preFilterType: String? = nil

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary
        setupNavBar()
        setupFilterChips()
        setupTableView()
        updateNavTitle()
        configureSecurity()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getAllDatas()
    }

    // MARK: - Nav Bar
    private func setupNavBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "vault.search_in_vault".localized()
        navigationItem.searchController = searchController
        definesPresentationContext = true

        let passwordItem = UIAction(title: "menu.password".localized(), image: UIImage(systemName: "person.badge.key.fill")) { _ in
            self.goToController(nameController: "NavDataPasswordController")
        }
        let creditCardItem = UIAction(title: "menu.credit_card".localized(), image: UIImage(systemName: "creditcard.fill")) { _ in
            self.goToController(nameController: "NavDataCreditCardController")
        }
        let secureNote = UIAction(title: "menu.secure_note".localized(), image: UIImage(systemName: "lock.rectangle.fill")) { _ in
            self.goToController(nameController: "NavDataSecureNoteController")
        }
        let imageItem = UIAction(title: "menu.image".localized(), image: UIImage(systemName: "photo.fill")) { _ in
            self.goToController(nameController: "NavDataImageController")
        }
        let menu = UIMenu(title: "menu.store_info".localized(), options: .displayInline, children: [passwordItem, creditCardItem, imageItem, secureNote])
        let rightButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), primaryAction: nil, menu: menu)
        rightButtonItem.tintColor = .accentBrand
        navigationItem.rightBarButtonItem = rightButtonItem
    }

    private func updateNavTitle() {
        if let type = preFilterType {
            title = VaultCategory.allCases.first { $0.typeKey == type }?.title ?? "vault.open".localized()
        } else {
            title = "vault.open".localized()
        }
    }

    // MARK: - Filter Chips
    private func setupFilterChips() {
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        filterStackView.axis = .horizontal
        filterStackView.spacing = 8
        filterStackView.translatesAutoresizingMaskIntoConstraints = false

        filterScrollView.addSubview(filterStackView)
        view.addSubview(filterScrollView)

        NSLayoutConstraint.activate([
            filterScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterScrollView.heightAnchor.constraint(equalToConstant: 40),

            filterStackView.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            filterStackView.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
            filterStackView.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor, constant: 16),
            filterStackView.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor, constant: -16),
            filterStackView.heightAnchor.constraint(equalTo: filterScrollView.heightAnchor),
        ])

        filterOptions.forEach { option in
            let button = makeChip(title: option.titleKey.localized(), type: option.type)
            filterStackView.addArrangedSubview(button)
            filterButtons.append(button)
        }

        styleChips()
    }

    private func makeChip(title: String, type: String?) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        config.cornerStyle = .capsule
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            return a
        }
        let button = UIButton(configuration: config)
        button.tag = filterOptions.firstIndex(where: { $0.type == type }) ?? 0
        button.addTarget(self, action: #selector(filterChipTapped(_:)), for: .touchUpInside)
        return button
    }

    private func styleChips() {
        for (index, button) in filterButtons.enumerated() {
            let option = filterOptions[index]
            let isActive = option.type == preFilterType || (option.type == nil && preFilterType == nil)
            let category = VaultCategory.allCases.first { $0.typeKey == (option.type ?? "") }
            let accent = category?.accent ?? .accentBrand
            var config = button.configuration ?? UIButton.Configuration.filled()
            config.baseForegroundColor = isActive ? accent : .textSecondary
            config.baseBackgroundColor = isActive ? accent.withAlphaComponent(0.15) : .backgroundSecondary
            button.configuration = config
        }
    }

    @objc private func filterChipTapped(_ sender: UIButton) {
        let option = filterOptions[sender.tag]
        preFilterType = option.type
        filteredDatas = option.type == nil ? lnkDatas : lnkDatas.filter { $0.typeData == option.type }
        updateNavTitle()
        styleChips()
        tableView.reloadData()
    }

    // MARK: - Table View
    private func setupTableView() {
        tableView.register(DatasViewCell.self, forCellReuseIdentifier: DatasViewCell.identifier)
        tableView.separatorColor = .border
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
        tableView.backgroundColor = .backgroundPrimary
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)

        refreshControl.attributedTitle = NSAttributedString(string: "vault.pull_to_refresh".localized())
        refreshControl.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        tableView.addSubview(refreshControl)

        // Pin table below filter chips
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Data
    private func getAllDatas() {
        if let preloaded = preloadedItems {
                lnkDatas      = preloaded
                filteredDatas  = preloaded
                tableView.reloadData()
                updateUI()
                return
            }
        DBManager.shared.getAllDatas(userID: Auth.auth().currentUser!.uid) { result in
            self.lnkDatas.removeAll()
            self.filteredDatas.removeAll()
            self.refreshControl.endRefreshing()

            guard let result else {
                self.updateUI()
                return
            }

            self.lnkDatas = result
            self.filteredDatas = self.preFilterType == nil
                ? result
                : result.filter { $0.typeData == self.preFilterType }
            self.tableView.reloadData()
            self.updateUI()
        }
    }

    private func updateUI() {
        searchController.searchBar.isHidden = lnkDatas.isEmpty
    }

    @objc private func refreshTable() {
        getAllDatas()
    }

    // MARK: - Navigation
    @objc private func goToController(nameController: String) {
        let storyboard = UIStoryboard(name: "Vault", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: nameController)
        present(vc, animated: true)
    }

    // MARK: - Security
    @objc private func configureSecurity() {
        let isNewUser = UserDefaults.standard.object(forKey: "is_new_user") as? Bool ?? true
        let isLocked = UserDefaults.standard.object(forKey: "locked_app") as? Bool ?? true

        guard !isNewUser else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "MasterPasswordController") as! MasterPasswordController
            vc.setPassword = true
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            return
        }

        if isLocked {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "MasterPasswordController") as! MasterPasswordController
            vc.setPassword = false
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate & DataSource
extension OpenVaultController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredDatas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DatasViewCell.identifier, for: indexPath) as! DatasViewCell
        cell.configure(model: filteredDatas[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = filteredDatas[indexPath.row]
        
        // Record last accessed
        recordAccess(for: model)

        switch model.typeData {
        case "type_1":
            let nav = storyboard?.instantiateViewController(withIdentifier: "NavDataCreditCardController") as! UINavigationController
            let vc = nav.viewControllers.first as! DataCreditCardController
            vc.nameData = model.nameData
            present(nav, animated: true)
        case "type_2":
            let nav = storyboard?.instantiateViewController(withIdentifier: "NavDataPasswordController") as! UINavigationController
            let vc = nav.viewControllers.first as! DataPasswordController
            vc.nameData = model.nameData
            present(nav, animated: true)
        case "type_3":
            let nav = storyboard?.instantiateViewController(withIdentifier: "NavDataSecureNoteController") as! UINavigationController
            let vc = nav.viewControllers.first as! DataSecureNoteController
            vc.nameData = model.nameData
            present(nav, animated: true)
        case "type_4":
            let nav = storyboard?.instantiateViewController(withIdentifier: "NavDataImageController") as! UINavigationController
            let vc = nav.viewControllers.first as! DataImageController
            vc.nameData = model.nameData
            present(nav, animated: true)
        default:
            let nav = storyboard?.instantiateViewController(withIdentifier: "NavDataSecureNoteController") as! UINavigationController
            let vc = nav.viewControllers.first as! DataPasswordController
            vc.nameData = model.nameData
            present(nav, animated: true)
        }
    }

    private func recordAccess(for item: LNKData) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("User")
            .document(uid)
            .collection("secret_datas")
            .document(item.nameData)
            .updateData(["lastAccessed": FieldValue.serverTimestamp()])
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let lnkData = filteredDatas[indexPath.row]

        DBManager.shared.deleteIndividualData(userID: Auth.auth().currentUser!.uid, lnkData: lnkData) { deleted in
            guard deleted else { return }
            self.filteredDatas.remove(at: indexPath.row)
            if let index = self.lnkDatas.firstIndex(where: { $0.nameData == lnkData.nameData }) {
                self.lnkDatas.remove(at: index)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)

            let alert = UIAlertController(title: "alert.deleted.title".localized(), message: "alert.deleted.message".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "button.ok".localized(), style: .default) { _ in
                self.navigationController?.popToRootViewController(animated: true)
            })
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UISearchResultsUpdating
extension OpenVaultController: UISearchResultsUpdating, UISearchControllerDelegate {

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text ?? "")
    }

    func filterContentForSearchText(_ searchText: String) {
        filteredDatas = searchText.isEmpty
            ? lnkDatas
            : lnkDatas.filter { $0.nameData.range(of: searchText, options: .caseInsensitive) != nil }
        tableView.reloadData()
    }
}
