//
//  DataImageControllerViewController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 7/9/22.
//

import UIKit
import FirebaseAuth


class DataImageController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var backViewTitle: UIView!
    
    public var nameData = ""
    var secretKey = ""
    var creationDate = 0
    var user = Auth.auth().currentUser
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backViewTitle.cornersView(border: false, roundedCorner: 10)
        
        if user  != nil {
            secretKey = user!.uid
            creationDate = Int(user!.metadata.creationDate!.timeIntervalSince1970)
        } else {
            print("NO user signed in")
            exit(0)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !nameData.isEmpty{
            titleTextField.text = nameData
            titleTextField.isEnabled = false
            saveButton.setTitle("Update", for: .normal)
            loadEncryptedData()
        } else {
            saveButton.setTitle("Save", for: .normal)
        }
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        if !nameData.isEmpty {
            updateDataImage()
        } else {
            saveDataImage()
        }
    }
    
    @IBAction func albumButtonTapped(_ sender: UIButton) {
        presentPhotoPicker()
    }
    
    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        presentCamera()
    }
    
    private func saveDataImage() {
        if titleTextField.text != "" {
            let encryptedData = encryptImage()
            if encryptedData != nil {
                DispatchQueue.main.async {
                    DBManager.shared.saveEncryptedDataImage(nameOfData: self.titleTextField.text!, lnkData: encryptedData!, userID: self.user!.uid) { success in
                        if success {
                            self.dismiss(animated: true)
                        }
                    }
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: "There was an error storing your image, try again later!", preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true)
            }
        } else {
            let alertController = UIAlertController(title: "Empty name", message: "What is the title you want to assign to this image?", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        }
    }
    
    private func loadEncryptedData(){
        DBManager.shared.downloadData(for: user!.uid, nameOfData: nameData) { result in
            switch result {
            case .success(let encryptedData):
                var decryptedImage = Encryption.shared.decryptImage(data: encryptedData, lengthKey: 10)
                if decryptedImage == nil {
                    decryptedImage = UIImage(named: "LogoIcon")!
                }
                DispatchQueue.main.async {
                    self.imageView.image = decryptedImage
                }
            case .failure(_):
                let alertController = UIAlertController(title: "Error", message: "There was an error downloading your image, try again later!", preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true)
            }
        }
    }
    
    private func updateDataImage() {
        let encryptedData = encryptImage()
        if encryptedData != nil {
            DispatchQueue.main.async {
                DBManager.shared.saveEncryptedDataImage(nameOfData: self.titleTextField.text!, lnkData: encryptedData!, userID: self.user!.uid) { success in
                    if success {
//                        self.dismiss(animated: true)
                        let alertController = UIAlertController(title: "Updated", message: "Your image has been updated successfully", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .default, handler: { _ in
                            self.dismiss(animated: true)
                        })
                        alertController.addAction(action)
                        
                        self.present(alertController, animated: true) {
                            print ("Update")
                        }
                        
                    }
                }
            }
        } else {
            let alertController = UIAlertController(title: "Error", message: "There was an error storing your image, try again later!", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        }
    }
    
    private func encryptImage() -> Data? {
        var image = UIImage()
        if imageView.image == nil {
            image = UIImage(named: "LogoIcon")!
        } else {
            image = imageView.image!
        }
        if let encryptedData = Encryption.shared.encryptImage(oldImage: image, lengthKey: 10) {
            return encryptedData
        } else {
            return nil
        }
    }
}



extension DataImageController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        guard  let selectedImage = info[.editedImage] as? UIImage else {
            return
        }
        imageView.image = selectedImage
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
}
