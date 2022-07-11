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
    
    public var nameData = ""
    var secretKey = ""
    var creationDate = 0
    var user = Auth.auth().currentUser
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            //TODO: Load encrypted image
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
            DispatchQueue.main.async {
                DBManager.shared.saveEncryptedDataImage(nameOfData: self.titleTextField.text!, lnkData: encryptedData, userID: self.user!.uid) { success in
                    if success {
                        print (success)
                    }
                }
            }
        } else {
            let alertController = UIAlertController(title: "Empty name", message: "What is the title you want to assign to this image?", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        }
    }
    
    private func updateDataImage() {
        //TODO: Save updated image / ??? Note: Consider this feature
    }
    
    private func encryptImage() -> Data {
        var image = UIImage()
        if imageView.image == nil {
            image = UIImage(named: "LogoIcon")!
        } else {
            image = imageView.image!
        }
        let encryptedData = Encryption.shared.encryptImage(oldImage: image, secretKey: secretKey, creationTime: creationDate)
        return encryptedData
    }
    
    private func decryptionImage() {
        //TODO: Decryption data
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
