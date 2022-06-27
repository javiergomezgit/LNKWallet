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
                //TODO: Goto master password unlock
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(goToSave))
//        let rightButtonImage = UIImage(systemName: "icloud.and.arrow.up.fill")?.withRenderingMode(.alwaysTemplate)
//        let rightButton = UIBarButtonItem(image: rightButtonImage, style: .plain, target: self, action: #selector(saveData))
//        self.navigationItem.rightBarButtonItem = rightButton
        
        
        if traitCollection.userInterfaceStyle == .light {
            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "darkblueAccent")!
        } else {
            navigationItem.rightBarButtonItem!.tintColor = UIColor(named: "mainOrange")!
        }
    }
    
    @objc private func goToSave() {
        self.tabBarController?.selectedIndex = 0
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
        
        let encryptedPasscode = UserDefaults.standard.value(forKey: "general_passcode") as! String
        if model.userData == nil {
            let decryptedContent = Encryption.shared.encryptDecrypt(oldMessage: model.contentData, encryptedPasscode: encryptedPasscode, secretKey: Auth.auth().currentUser!.uid, encrypt: false)
            let data = convertContentForReading(mergedContent: decryptedContent, nameData: model.nameData)

            let vc = storyboard?.instantiateViewController(withIdentifier: "EditDataController") as! EditDataController
            vc.title = "Editing"
            vc.configure(lockData: data)
            vc.navigationItem.largeTitleDisplayMode = .always
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let decryptedContent = Encryption.shared.encryptDecrypt(oldMessage: model.contentData, encryptedPasscode: encryptedPasscode, secretKey: Auth.auth().currentUser!.uid, encrypt: false)
            let decryptedUser = Encryption.shared.encryptDecrypt(oldMessage: model.userData!, encryptedPasscode: encryptedPasscode, secretKey: Auth.auth().currentUser!.uid, encrypt: false)
            
            print (decryptedContent)
            print (decryptedUser)
            print (model)
            
            let data = convertPassForReading(passwordContent: decryptedContent, userContent: decryptedUser, namePassword: model.nameData)
            let vc = storyboard?.instantiateViewController(withIdentifier: "EditPasswordController") as! EditPasswordController
            //self.present(vc, animated: true)
            vc.title = "Editing".localized()
            vc.configurePass(lockDataPassword: data)
            vc.navigationItem.largeTitleDisplayMode = .always
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let lnkData = lnkDatas[indexPath.row]
        print (lnkData.nameData)
        
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
    
    func convertContentForReading(mergedContent: String, nameData: String) -> LockData{
        
        let components = mergedContent.components(separatedBy: "*")
        let code = components[0]
        let date = components[1]
        let number = components[2]
        let name = components[3]
        
        let data = LockData(nameData: nameData, nameOnCard: name, numberCard: number, expDate: date, securityCode: code)
        return data
    }
    
    func convertPassForReading(passwordContent: String, userContent: String, namePassword: String) -> LockDataPassword {

        let components = userContent.components(separatedBy: " ")
        let username = components[0]
        let email = components[1]
        
        let data = LockDataPassword(nameData: namePassword, username: username, email: email, password: passwordContent)
        return data
    }
    
}
