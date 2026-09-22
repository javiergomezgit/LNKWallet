//
//  CredentialListViewController.swift
//  LNK AutoFill
//
//  Created by Javier Gomez on 9/22/26.
//

import UIKit

// One password, decrypted, as the list shows and fills it. Exists only after the unlock gate.
struct FillItem {
    let documentID: String
    let name:       String
    let user:       String  // username, or email when there is no username (same rule as the QuickType identity)
    let password:   String
    let host:       String? // normalized website, nil when the item has none

    init(decrypting encrypted: PasswordRecord, secretKey: String, creationDate: Int) {
        let decrypted = encrypted.decrypted(secretKey: secretKey, creationDate: creationDate)
        documentID    = encrypted.documentID
        name          = decrypted.nameData
        user          = decrypted.username.isEmpty ? decrypted.email : decrypted.username
        password      = decrypted.password
        host          = ServiceHost.normalized(decrypted.website)
    }
}

// Every password in the vault, with the ones for the site being filled on top, and search.
final class CredentialListViewController: UITableViewController {

    // MARK: — State
    var onSelect: ((FillItem) -> Void)?
    var onCancel: (() -> Void)?

    private let items:        [FillItem]? // nil when the app hasn't written the offline copy yet
    private let requestHosts: [String]
    private let searchController = UISearchController(searchResultsController: nil)

    private var suggested: [FillItem] = []
    private var all:       [FillItem] = []
    private var results:   [FillItem] = []

    private var isSearching: Bool {
        !(searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: — Lifecycle

    init(items: [FillItem]?, serviceIdentifiers: [String]) {
        self.items        = items
        self.requestHosts = serviceIdentifiers.compactMap { ServiceHost.normalized($0) }
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupSearch()
        setupTable()
        groupItems()
    }

    // MARK: — Setup

    private func setupNavBar() {
        styleFormNavBar(title: "autofill.list.title".localized())

        let cancelButton = UIBarButtonItem(title: "button.cancel".localized(),
                                           style: .plain,
                                           target: self,
                                           action: #selector(cancelTapped))
        cancelButton.tintColor = .textSecondary
        navigationItem.leftBarButtonItem = cancelButton
    }

    private func setupSearch() {
        searchController.searchResultsUpdater                 = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder                = "autofill.list.search".localized()
        searchController.searchBar.tintColor                  = .accentBrand
        navigationItem.searchController                       = searchController
        navigationItem.hidesSearchBarWhenScrolling            = false
    }

    private func setupTable() {
        tableView.backgroundColor = .backgroundPrimary
        tableView.separatorColor  = .border
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FillItemCell")
    }

    private func groupItems() {
        let sorted = (items ?? []).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        all       = sorted
        suggested = sorted.filter { item in
            guard let host = item.host else { return false }
            return requestHosts.contains { ServiceHost.matches(host, $0) }
        }
        updateEmptyState()
    }

    private func updateEmptyState() {
        let message: String?
        if items == nil {
            message = "autofill.list.no_copy".localized()
        } else if all.isEmpty {
            message = "autofill.list.empty".localized()
        } else if isSearching && results.isEmpty {
            message = "autofill.list.no_results".localized()
        } else {
            message = nil
        }

        guard let message = message else {
            tableView.backgroundView = nil
            return
        }
        let label = UILabel()
        label.text          = message
        label.font          = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor     = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        tableView.backgroundView = label
        label.frame              = tableView.bounds.insetBy(dx: 32, dy: 0)
    }

    // MARK: — Actions

    @objc private func cancelTapped() {
        onCancel?()
    }

    // MARK: — Table

    private func rows(in section: Int) -> [FillItem] {
        if isSearching { return results }
        return (section == 0 && !suggested.isEmpty) ? suggested : all
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isSearching { return results.isEmpty ? 0 : 1 }
        if all.isEmpty { return 0 }
        return suggested.isEmpty ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows(in: section).count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearching { return "autofill.list.results".localized() }
        if section == 0 && !suggested.isEmpty, let host = requestHosts.first {
            return "autofill.list.suggested".localized(with: host)
        }
        return "autofill.list.all".localized()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FillItemCell", for: indexPath)
        let item = rows(in: indexPath.section)[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text                          = item.name
        content.secondaryText                 = [item.user, item.host].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        content.image                         = UIImage(systemName: "key.fill")
        content.imageProperties.tintColor     = .accentBrand
        content.textProperties.color          = .textPrimary
        content.secondaryTextProperties.color = .textSecondary
        cell.contentConfiguration = content
        cell.backgroundColor      = .backgroundSecondary
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect?(rows(in: indexPath.section)[indexPath.row])
    }
}

// MARK: — UISearchResultsUpdating

extension CredentialListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespaces)
        results = all.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.user.localizedCaseInsensitiveContains(query) ||
            ($0.host ?? "").localizedCaseInsensitiveContains(query)
        }
        tableView.reloadData()
        updateEmptyState()
    }
}
