//
//  DBManager.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/26/21.
//

import Foundation
import FirebaseFirestore
import CloudKit
import FirebaseAuth
import FirebaseStorage

final class DBManager {
    static let shared = DBManager()
    
    //MARK: iCloud Database
    private let databaseCloudKit = CKContainer(identifier: "iCloud.com.jdev.Lock-n-Key-Wallet").publicCloudDatabase
    private let recordTypeName = "Passcodes"
    private let passcodeNameDB = "encrypted_passcode"
    private let firebaseNameDB = "firebase_id"
    
    
    //    public func createNewUser() {
    //        let db = Firestore.firestore()
    //        db.collection("User").document(user.uid).setData(["email": email, "displayName": displayName, "uid": user.uid]) { err in
    //            if let err = err {
    //                print("Error writing document: \(err)")
    //            } else {
    //                print("the user has sign up or is logged in")
    //            }
    //        }
    //    }
    
    public func saveMasterPassword(userID: String, encryptedPassword: String, completion: @escaping(Bool) -> Void) {
        let ckRecordZoneID = CKRecordZone.ID(zoneName: "_defaultZone", ownerName: CKCurrentUserDefaultName)
        let ckRecordID = CKRecord.ID(recordName: userID, zoneID: ckRecordZoneID)
        let record = CKRecord(recordType: recordTypeName, recordID: ckRecordID)
        record.setValue(encryptedPassword, forKey: passcodeNameDB)
        record.setValue(userID, forKey: firebaseNameDB)
        
        databaseCloudKit.save(record) { record, error in
            if record != nil, error == nil {
                print ("saved")
                UserDefaults.standard.set(true, forKey: "found_passcode")
                UserDefaults.standard.set(true, forKey: "passcode_saved")
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    public func downloadMasterPassword(userID: String, completion: @escaping(String?) -> Void) {
        let query = CKQuery(recordType: recordTypeName, predicate: NSPredicate(value: true))
        let ckRecordZoneID = CKRecordZone.ID(zoneName: "_defaultZone", ownerName: CKCurrentUserDefaultName)
        databaseCloudKit.perform(query, inZoneWith: ckRecordZoneID) { [weak self] records, error in
            guard let records = records, error == nil else {
                return
            }
            
            for record in records {
                let id = record.value(forKey: self!.firebaseNameDB) as! String
                if id == userID {
                    print ("found general passcode")
                    let foundRecord = record.value(forKey: self!.passcodeNameDB) as! String
                    UserDefaults.standard.set(true, forKey: "found_passcode")
                    completion(foundRecord)
                } else {
                    UserDefaults.standard.set(false, forKey: "found_passcode")
                    completion(nil)
                }
            }
        }
    }
    
    
    //MARK: Firebase Database
    private let database = Firestore.firestore()
    
    public func verifyUserExists(userID: String, completion: @escaping(Bool) -> Void) {
        database.collection("User").getDocuments { snapshot, error in
            var foundUser = ""
            if error != nil {
                print (error as Any)
                completion(false)
            }
            if let documents = snapshot?.documents  {
                for document in documents {
                    if userID == document.documentID {
                        foundUser = userID
                        break
                    }
                }
                if foundUser.isEmpty {
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    public func getEncryptedDataCreditCard(userID: String, nameData: String, completion: @escaping(LNKDataCreditCard?) -> Void) {
        database.collection("User").document(userID).collection("secret_datas").document(nameData).getDocument { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(nil)
            } else {
                //let typeData = snapshot!.get("key0") as! String //type
                //let name = snapshot!.get("key1") as! String //name
                let name = snapshot!.get("key2") as! String //name on card
                let number = snapshot!.get("key3") as! String //number
                let ccv = snapshot!.get("key4") as! String //ccv
                let zip = snapshot!.get("key5") as! String //zip code
                let exp = snapshot!.get("key6") as! String //expiration
                
                let lnkDataPassword = LNKDataCreditCard(nameData: nameData, nameOnCard: name, numberCard: number, securityCode: ccv, zipCode: zip, expDate: exp)
                completion(lnkDataPassword)
            }
        }
    }
    
    public func saveEncryptedCreditCard(nameOfData: String, lnkDataCreditCard: LNKDataCreditCard, userID: String, completion: @escaping(Bool) -> Void) {
        //Using generic words for security.
        let content = ["key0" : "type_1",
                       "key1" : lnkDataCreditCard.nameData,
                       "key2" : lnkDataCreditCard.nameOnCard,
                       "key3" : lnkDataCreditCard.numberCard,
                       "key4" : lnkDataCreditCard.securityCode,
                       "key5" : lnkDataCreditCard.zipCode,
                       "key6" : lnkDataCreditCard.expDate
        ]
        
        database.collection("User").document(userID).collection("secret_datas").document(nameOfData).setData(content) { error in
            if error != nil {
                completion(false)
            } else {
                print ("save encrypted data")
                completion(true)
            }
        }
    }
    
    public func updateEncryptedCreditCard(nameOfData: String, lnkDataCreditCard: LNKDataCreditCard, userID: String, completion: @escaping(Bool) -> Void) {
        //Using generic words for security.
        let content = ["key0" : "type_1",
                       "key1" : lnkDataCreditCard.nameData,
                       "key2" : lnkDataCreditCard.nameOnCard,
                       "key3" : lnkDataCreditCard.numberCard,
                       "key4" : lnkDataCreditCard.securityCode,
                       "key5" : lnkDataCreditCard.zipCode,
                       "key6" : lnkDataCreditCard.expDate
        ]
        
        database.collection("User").document(userID).collection("secret_datas").document(nameOfData).setData(content) { error in
            if error != nil {
                completion(false)
            } else {
                print ("save encrypted data")
                completion(true)
            }
        }
    }
    
    public func saveEncryptedDataImage(nameOfData: String, lnkData: Data, userID: String, completion: @escaping(Bool) -> Void) {
        
        uploadPhoto(with: lnkData, nameOfData: nameOfData, userID: userID, completion: { urlData in
            if urlData != nil {
                let content = ["key0" : "type_4",
                               "key1" : nameOfData, //name of data
                               "key2" : urlData! //url of the data
                ]
                self.database.collection("User").document(userID).collection("secret_datas").document(nameOfData).setData(content) { error in
                    if error != nil {
                        completion(false)
                    } else {
                        print ("save encrypted data")
                        completion(true)
                    }
                }
                completion(true)
            } else {
                print ("ERROR")
                completion(false)
            }
        })
    }
    
    
    
    public func getEncryptedDataPassword(userID: String, nameData: String, completion: @escaping(LNKDataPassword?) -> Void) {
        database.collection("User").document(userID).collection("secret_datas").document(nameData).getDocument { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(nil)
            } else {
                
                //let typeData = snapshot!.get("key0") as! String //type
                //let name = snapshot!.get("key1") as! String //name
                let username = snapshot!.get("key2") as! String //username
                let email = snapshot!.get("key3") as! String //email
                let password = snapshot!.get("key4") as! String //password
                let website = snapshot!.get("key5") as! String //website
                
                let lnkDataPassword = LNKDataPassword(nameData: nameData, email: email, username: username, password: password, website: website)
                completion(lnkDataPassword)
            }
        }
    }
    
    public func saveEncryptedDataPassword(nameOfData: String, lnkDataPassword: LNKDataPassword, userID: String, completion: @escaping(Bool) -> Void) {
        database.collection("User").document(userID).collection("secret_datas").document(nameOfData).getDocument { snap, error in
            if error == nil {
                var newNameOfData = nameOfData
                if snap!.exists {
                    //Alredy exists, can't have repeted names
                    newNameOfData = "\(nameOfData)-2"
                }
                //Using generic words for security.
                let content = ["key0" : "type_2",
                               "key1" : lnkDataPassword.nameData,
                               "key2" : lnkDataPassword.username,
                               "key3" : lnkDataPassword.email,
                               "key4" : lnkDataPassword.password,
                               "key5" : lnkDataPassword.website
                ]
                
                self.database.collection("User").document(userID).collection("secret_datas").document(newNameOfData).setData(content) { error in
                    if error != nil {
                        completion(false)
                    } else {
                        print ("save encrypted data")
                        completion(true)
                    }
                }
            } else {
                print ("error find the database \(String(describing: error))")
                completion(false)
            }
        }
    }
    
    public func updateEncryptedDataPassword(nameOfData: String, lnkDataPassword: LNKDataPassword, userID: String, completion: @escaping(Bool) -> Void) {
        //Using generic words for security.
        let content = ["key0" : "type_2",
                       "key1" : lnkDataPassword.nameData,
                       "key2" : lnkDataPassword.username,
                       "key3" : lnkDataPassword.email,
                       "key4" : lnkDataPassword.password,
                       "key5" : lnkDataPassword.website
        ]
        
        database.collection("User").document(userID).collection("secret_datas").document(nameOfData).setData(content) { error in
            if error != nil {
                completion(false)
            } else {
                print ("save encrypted data")
                completion(true)
            }
        }
    }
    
    public func getEncryptedDataSecureNote(userID: String, nameData: String, completion: @escaping(LNKDataSecureNote?) -> Void) {
        database.collection("User").document(userID).collection("secret_datas").document(nameData).getDocument { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(nil)
            } else {
                
                //let typeData = snapshot!.get("key0") as! String //type
                //let name = snapshot!.get("key1") as! String //name
                let secureNote = snapshot!.get("key2") as! String //secure note
                
                let lnkDataSecureNote = LNKDataSecureNote(nameData: nameData, secureNote: secureNote)
                completion(lnkDataSecureNote)
            }
        }
    }
    
    public func saveEncryptedDataSecureNote(nameOfData: String, lnkDataSecureNote: LNKDataSecureNote, userID: String, completion: @escaping(Bool) -> Void) {
        database.collection("User").document(userID).collection("secret_datas").document(nameOfData).getDocument { snap, error in
            if error == nil {
                var newNameOfData = nameOfData
                if snap!.exists {
                    //Alredy exists, can't have repeted names
                    newNameOfData = "\(nameOfData)-2"
                }
                //Using generic words for security.
                let content = ["key0" : "type_3",
                               "key1" : lnkDataSecureNote.nameData,
                               "key2" : lnkDataSecureNote.secureNote
                ]
                
                self.database.collection("User").document(userID).collection("secret_datas").document(newNameOfData).setData(content) { error in
                    if error != nil {
                        completion(false)
                    } else {
                        print ("save encrypted data")
                        completion(true)
                    }
                }
            } else {
                print ("error find the database \(String(describing: error))")
                completion(false)
            }
        }
    }
    
    public func updateEncryptedDataSecureNote(nameOfData: String, lnkDataSecureNote: LNKDataSecureNote, userID: String, completion: @escaping(Bool) -> Void) {
        //Using generic words for security.
        let content = ["key0" : "type_3",
                       "key1" : lnkDataSecureNote.nameData,
                       "key2" : lnkDataSecureNote.secureNote
        ]
        
        database.collection("User").document(userID).collection("secret_datas").document(nameOfData).setData(content) { error in
            if error != nil {
                completion(false)
            } else {
                print ("save encrypted data")
                completion(true)
            }
        }
    }
    
    public func getAllDatas(userID: String, completion: @escaping([LNKData]?) -> Void) {
        database.collection("User").document(userID).collection("secret_datas").getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(nil)
            } else {
                var datasFound: [LNKData] = [LNKData]()
                for document in snapshot!.documents {
                    let nameData = document.documentID
                    let typeData = document.get("key0") as! String
                    let lnkData = LNKData(nameData: nameData, typeData: typeData)
                    datasFound.append(lnkData)
                }
                completion(datasFound)
            }
        }
    }
    
    public func deleteAllDatas(userID: String, completion: @escaping(Bool) -> Void) {
        database.collection("User").document(userID).collection("secret_datas").getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(false)
            } else {
                for document in snapshot!.documents {
                    let nameData = document.documentID
                    self.database.collection("User").document(userID).collection("secret_datas").document(nameData).delete()
                }
                self.deleteFolderData(userID: userID) { success in
                    if success {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
    
    public func deleteIndividualData(userID: String, lnkData: LNKData, completion: @escaping(Bool) -> Void) {
        let nameOfData = lnkData.nameData
        database.collection("User").document(userID).collection("secret_datas").document(nameOfData).delete { error in
            if (error != nil) {
                completion(false)
            } else {
                if lnkData.typeData == "type_4" {
                    self.deleteData(userID: userID, nameOfData: nameOfData) { success in
                        if success {
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                }
                
            }
        }
    }
    
    public func deleteAccount(userID: String, completion: @escaping(Bool) -> Void) {
        database.collection("User").document(userID).delete { error in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(false)
            } else {
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
                
                let recordID = CKRecord.ID(recordName: userID)
                self.databaseCloudKit.delete(withRecordID: recordID) { record, error in
                    if let record = record, error == nil {
                        print ("\(record) Records on CLOUDKIT are deleted")
                        Auth.auth().currentUser?.delete(completion: { error in
                            if let error = error  {
                                print ("\(error) error happened deleting firebase user")
                            } else {
                                self.deleteAllDatas(userID: userID) { success in
                                    if success {
                                        completion(true)
                                    } else {
                                        completion(false)
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    public func deletePasscode(userID: String, completion: @escaping(Bool) -> Void) {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
        
        database.collection("User").document(userID).collection("secret_datas").getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(false)
            } else {
                for document in snapshot!.documents {
                    let nameData = document.documentID
                    self.database.collection("User").document(userID).collection("secret_datas").document(nameData).delete()
                }
                let recordID = CKRecord.ID(recordName: userID)
                self.databaseCloudKit.delete(withRecordID: recordID) { record, error in
                    if let record = record, error == nil {
                        print ("\(record) Records on CLOUDKIT are deleted")
                        if let error = error  {
                            print ("\(error) error happened deleting CLOUDKIT user")
                        } else {
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    
    //MARK: Fire storage
    private let storage = Storage.storage().reference()
    
    ///Upload photo to storage
    public func uploadPhoto(with data: Data, nameOfData: String, userID: String, completion: @escaping(String?) -> Void) {
        storage.child("stored_images/\(userID)/\(nameOfData)").putData(data) { result in
            switch result {
            case .success(let metadata):
                print (metadata)
                self.storage.child("stored_images/\(userID)/\(nameOfData)").downloadURL { url, error in
                    guard let url = url else {
                        completion(nil)
                        return
                    }
                    let urlString = url.absoluteString
                    print (urlString)
                    completion(urlString)
                }
            case .failure(let error):
                print (error)
                completion(nil)
            }
        }
    }
    
    ///Download Imge
    public func downloadData(for userID: String, nameOfData: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let path = "stored_images/\(userID)/\(nameOfData)"
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(error!))
                return
            }
            let dataTask = URLSession.shared.dataTask(with: url) { data, responseURL, error in
                if let data = data {
                    completion(.success(data))
                } else {
                    completion(.failure(error!))
                }
            }
            dataTask.resume()
        }
    }
    
    ///Delete  data
    public func deleteData(userID: String, nameOfData: String, completion: @escaping (Bool) -> Void) {
        let path = "stored_images/\(userID)/\(nameOfData)"
        let reference = storage.child(path)
     
        reference.delete { error in
            if error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    ///Delete all data for a folder
    public func deleteFolderData(userID: String, completion: @escaping (Bool) -> Void) {
        let path = "stored_images/\(userID)/"
        let reference = storage.child(path)
     
        reference.listAll { result in
            switch result {
                
            case .success(let listItems):
                for item in listItems.items {
                    item.delete { error in
                        print (error as Any)
                    }
                }
                completion(true)
            case .failure(let error):
                completion(false)
                print ("error \(error)")
            }
        }
    }
}






