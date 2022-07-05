//
//  OpenVaultController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/19/21.
//

import UIKit
import FirebaseAuth

class OpenVaultController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let refreshControl = UIRefreshControl()
    
    private var lnkDatas = [LNKData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Open Vault".localized()
        configureTops()
        configureSecurity()
        
        tableView.register(DatasViewCell.nib, forCellReuseIdentifier: DatasViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh".localized())
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
            //TODO: SHOW master password set password
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
        let creditCardItem = UIAction(title: "Credit Card", image: UIImage(systemName: "creditcard")) { (action) in
            print("Credit card was tapped")
            self.goToController(nameController: "DataCreditCardController")
        }
        
        let passwordItem = UIAction(title: "Password", image: UIImage(systemName: "staroflife.fill")) { (action) in
            print("Password action was tapped")
            self.goToController(nameController: "DataPasswordController")
        }
        
        let secureNote = UIAction(title: "Secure Note", image: UIImage(systemName: "note.text")) { (action) in
            print("Secure note was tapped")
            self.goToController(nameController: "DataSecureNoteController")
            //TODO: Crete controller for secure data
        }
        let menu = UIMenu(title: "Store new information", options: .displayInline, children: [creditCardItem , passwordItem , secureNote])
        
        let rightButtonItem = UIBarButtonItem(image:  UIImage(systemName: "plus"), primaryAction: nil, menu: menu)
        
        self.navigationItem.rightBarButtonItem = rightButtonItem
        
        
        if traitCollection.userInterfaceStyle == .light {
            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "darkblueAccent")!
        } else {
            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "mainOrange")!
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
            
            self.refreshControl.endRefreshing()
            if result != nil {
                self.lnkDatas = result!
                self.tableView.reloadData()
            }
        }
    }
}

extension OpenVaultController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lnkDatas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = lnkDatas[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: DatasViewCell.identifier, for: indexPath) as! DatasViewCell
        
        cell.configure(model: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = lnkDatas[indexPath.row]
        
        if model.typeData == "type_2" {
            let vc = storyboard?.instantiateViewController(withIdentifier: "DataPasswordController") as! DataPasswordController
            vc.nameData = model.nameData
//            self.navigationController?.pushViewController(vc, animated: true)
            self.present(vc, animated: true)
        } else if model.typeData == "type_1"{
            let vc = storyboard?.instantiateViewController(withIdentifier: "DataCreditCardController") as! DataCreditCardController
            vc.nameData = model.nameData
            self.present(vc, animated: true)
//            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = storyboard?.instantiateViewController(withIdentifier: "DataSecureNoteController") as! DataSecureNoteController
            vc.nameData = model.nameData
            self.present(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let lnkData = lnkDatas[indexPath.row]
        
        if editingStyle == .delete {
            DBManager.shared.deleteIndividualData(userID: Auth.auth().currentUser!.uid, nameOfData: lnkData.nameData) { deleted in
                if deleted {
                    self.lnkDatas.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    let alert = UIAlertController(title: "Deleted".localized(), message: "The information has been deleted".localized(), preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                        self.navigationController?.popToRootViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}
