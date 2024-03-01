//
//  OpenVaultController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/19/21.
//

import UIKit
import FirebaseAuth

class OpenVaultController: UIViewController {
    
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var passButton: UIButton!
    @IBOutlet weak var ccButton: UIButton!
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    let refreshControl = UIRefreshControl()
    private var lnkDatas = [LNKData]()
    //Search & Filter
    private var filteredDatas = [LNKData]()
    private var searchController = UISearchController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Open Vault"
        
        configureTops()
        configureSecurity()
        
        tableView.register(DatasViewCell.nib, forCellReuseIdentifier: DatasViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refreshTable), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
    }
    
    @objc func refreshTable(notification: NSNotification) {
        getAllDatas()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getAllDatas()
        
    }
    
    @objc private func configureSecurity() {
        //        if (UserDefaults.standard.value(forKey: "found_passcode") as! Bool) == false {
        //            UserDefaults.standard.set(true, forKey: "is_new_user")
        //        }
        
        if UserDefaults.standard.value(forKey: "is_new_user") as! Bool == true {
            print ("NEW USER")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "MasterPasswordController") as! MasterPasswordController
            vc.setPassword = true
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        } else {
            if UserDefaults.standard.value(forKey: "locked_app") as! Bool == true {
                //Goto master password unlock 
                print ("NOT NEW USER")
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(identifier: "MasterPasswordController") as! MasterPasswordController
                vc.setPassword = false
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        }
    }
    
    private func configureTops() {
        
        allButton.roundCorners(amountCornerPercentage: 100)
        passButton.roundCorners(amountCornerPercentage: 100)
        ccButton.roundCorners(amountCornerPercentage: 100)
        noteButton.roundCorners(amountCornerPercentage: 100)
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search in Vault"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
//        let creditCardItem = UIAction(title: "Credit Card", image: UIImage(systemName: "creditcard")) { (action) in
//            print("Credit card was tapped")
//            self.goToController(nameController: "DataCreditCardController")
//        }
            
        let passwordItem = UIAction(title: "Password", image: UIImage(systemName: "staroflife.fill")) { (action) in
            print("Password action was tapped")
            self.goToController(nameController: "DataPasswordController")
        }
        
        let secureNote = UIAction(title: "Secure Note", image: UIImage(systemName: "note.text")) { (action) in
            print("Secure note was tapped")
            self.goToController(nameController: "DataSecureNoteController")
        }
        
        let imageItem = UIAction(title: "Image", image: UIImage(named: "photo.circle")) { (action) in
            print("Image was tapped")
            self.goToController(nameController: "DataImageController")
        }
        let menu = UIMenu(title: "Store new information", options: .displayInline, children: [passwordItem, imageItem, secureNote])
        
        let rightButtonItem = UIBarButtonItem(image:  UIImage(systemName: "plus"), primaryAction: nil, menu: menu)
        
        self.navigationItem.rightBarButtonItem = rightButtonItem
        
        
        if traitCollection.userInterfaceStyle == .light {
            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "darkblueAccent")!
        } else {
            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "mainOrange")!
        }
    }
    
    func updateUI() {
        if self.lnkDatas.isEmpty {
            self.searchController.searchBar.isHidden = true
        } else {
            self.searchController.searchBar.isHidden = false
        }
    }
    
    @objc private func goToController(nameController: String) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: nameController)
        //        vc.definesPresentationContext = true
        //        vc.modalPresentationStyle = .overCurrentContext
        //        navigationController?.present(vc, animated: true, completion: nil)
        self.present(vc, animated: true)
        //        self.show(vc, sender: nil)
    }
    
    private func getAllDatas(){
        DBManager.shared.getAllDatas(userID: Auth.auth().currentUser!.uid) { result in
            
            self.lnkDatas.removeAll()
            self.filteredDatas.removeAll()
            self.refreshControl.endRefreshing()
            
            if result != nil {
                self.lnkDatas = result!
                self.filteredDatas = result!
                self.tableView.reloadData()
                self.updateUI()
            } else {
                self.updateUI()
            }
        }
    }
    
    @IBAction func showAllTapped(_ sender: UIButton) {
        filteredDatas = lnkDatas
        tableView.reloadData()
    }
    
    
    @IBAction func showPasswordsTapped(_ sender: Any) {
        filteredDatas = false ? lnkDatas : lnkDatas.filter({ lnkData in
            return lnkData.typeData.range(of: "type_2", options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        tableView.reloadData()
    }
    
    @IBAction func showCreditCardsTapped(_ sender: UIButton) {
        filteredDatas = false ? lnkDatas : lnkDatas.filter({ lnkData in
            return lnkData.typeData.range(of: "type_4", options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        tableView.reloadData()
    }
    
    @IBAction func showSecureNoteTapped(_ sender: Any) {
        filteredDatas = false ? lnkDatas : lnkDatas.filter({ lnkData in
            return lnkData.typeData.range(of: "type_3", options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        tableView.reloadData()
    }
    
}

extension OpenVaultController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredDatas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = filteredDatas[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: DatasViewCell.identifier, for: indexPath) as! DatasViewCell
        
        cell.configure(model: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = filteredDatas[indexPath.row]
        
        if model.typeData == "type_2" {
            let vc = storyboard?.instantiateViewController(withIdentifier: "DataPasswordController") as! DataPasswordController
            vc.nameData = model.nameData
            self.present(vc, animated: true)
        } else if model.typeData == "type_1"{
            let vc = storyboard?.instantiateViewController(withIdentifier: "DataCreditCardController") as! DataCreditCardController
            vc.nameData = model.nameData
            self.present(vc, animated: true)
        } else if model.typeData == "type_4" {
            let vc = storyboard?.instantiateViewController(withIdentifier: "DataImageController") as! DataImageController
            vc.nameData = model.nameData
            self.present(vc, animated: true)
        } else {
            let vc = storyboard?.instantiateViewController(withIdentifier: "DataSecureNoteController") as! DataSecureNoteController
            vc.nameData = model.nameData
            self.present(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let lnkData = filteredDatas[indexPath.row]
        
        if editingStyle == .delete {
            DBManager.shared.deleteIndividualData(userID: Auth.auth().currentUser!.uid, lnkData: lnkData) { deleted in
                if deleted {
                    self.filteredDatas.remove(at: indexPath.row)
                    self.lnkDatas.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    let alert = UIAlertController(title: "Deleted", message: "The information has been deleted", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                        self.navigationController?.popToRootViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}


extension OpenVaultController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredDatas = searchText.isEmpty ? lnkDatas : lnkDatas.filter({ lnkData in
            return lnkData.nameData.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        tableView.reloadData()
    }
}
