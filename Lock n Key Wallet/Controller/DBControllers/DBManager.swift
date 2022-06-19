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
//import AVKit

final class DBManager {
    static let shared = DBManager()
    
    private let database = Firestore.firestore()
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
    
    public func saveEncryptedData(nameOfData: String, contentData: String, userID: String, completion: @escaping(Bool) -> Void) {
        database.collection("User").document(userID).collection("secret_datas").document(nameOfData).setData(["data_content" : contentData]) { error in
            if error != nil {
                completion(false)
            } else {
                print ("save encrypted data")
                completion(true)
            }
        }
    }
    
    public func saveEncryptedDataPasswords(nameOfDataPassword: String, contentDataPassword: String, user: String, userID: String, completion: @escaping(Bool) -> Void) {
        let content = ["data_content" : contentDataPassword, "user" : user]
        
        database.collection("User").document(userID).collection("secret_datas").document(nameOfDataPassword).setData(content) { error in
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
                var lnkDatas: [LNKData] = [LNKData]()
                
                for document in snapshot!.documents {
                    let nameData = document.documentID
                    let contentData = document.get("data_content") as! String
                    
                    if let userPass = document.get("user") as? String {
                        let lnkPass = LNKData(nameData: nameData, userData: userPass, contentData: contentData)
                        lnkDatas.append(lnkPass)
                    } else {
                        let lnkData = LNKData(nameData: nameData, userData: nil, contentData: contentData)
                        lnkDatas.append(lnkData)
                    }
                }
                completion(lnkDatas)
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
                completion(true)
            }
        }
    }
    
    public func deleteIndividualData(userID: String, nameOfData: String, completion: @escaping(Bool) -> Void) {
        database.collection("User").document(userID).collection("secret_datas").document(nameOfData).delete { error in
            if (error != nil) {
                completion(false)
            } else {
                completion(true)
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
                                completion(true)
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
}
