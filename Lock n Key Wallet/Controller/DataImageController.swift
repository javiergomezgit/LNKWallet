//
//  DataImageControllerViewController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 7/9/22.
//

import UIKit
import FirebaseAuth

class DataImageController: UIViewController {

    // MARK: — Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var backViewTitle: UIView!

    // MARK: — State
    public var nameData  = ""
    var secretKey        = ""
    var creationDate     = 0
    var user = Auth.auth().currentUser

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary

        setupNavBar()
        setupFields()
        setupUser()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.rightBarButtonItem?.title = nameData.isEmpty ? "Save" : "Update"
        self.title = nameData.isEmpty ? "New Image" : "Image"

        if !nameData.isEmpty {
            titleTextField.text      = nameData
            titleTextField.isEnabled = false
            loadEncryptedData()
        }
    }

    // MARK: — Setup

    private func setupNavBar() {
        styleFormNavBar(title: "")

        let closeBtn = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(exitButtonTapped))
        closeBtn.tintColor = .textSecondary
        navigationItem.leftBarButtonItem = closeBtn

        let saveBtn = UIBarButtonItem(title: "Save",
                                     style: .done,
                                     target: self,
                                     action: #selector(saveButtonTapped))
        saveBtn.tintColor = .accentImages
        navigationItem.rightBarButtonItem = saveBtn
    }

    private func setupFields() {
        styleTextField(titleTextField, placeholder: "Image title", accent: .accentImages)

        backViewTitle.backgroundColor    = .backgroundSecondary
        backViewTitle.layer.cornerRadius = 12
        backViewTitle.layer.borderWidth  = 0.5
        backViewTitle.layer.borderColor  = UIColor.border.cgColor
    }

    private func setupUser() {
        guard let u = user else { exit(0) }
        secretKey    = u.uid
        creationDate = Int(u.metadata.creationDate!.timeIntervalSince1970)
    }

    // MARK: — Actions

    @IBAction func exitButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @objc private func saveButtonTapped() {
        nameData.isEmpty ? saveDataImage() : updateDataImage()
    }

    @IBAction func albumButtonTapped(_ sender: UIButton) {
        presentPhotoPicker()
    }

    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        presentCamera()
    }

    // MARK: — Data operations

    private func saveDataImage() {
        guard verifyFields() else { return }
        guard let encrypted = encryptImage() else {
            showAlert(title: "Error", message: "There was an error storing your image. Try again later.")
            return
        }
        DispatchQueue.main.async {
            DBManager.shared.saveEncryptedDataImage(
                nameOfData: self.titleTextField.text!.sanitizeNameForDB(),
                lnkData: encrypted,
                userID: self.user!.uid) { [weak self] success in
                guard let self = self, success else { return }
                self.dismiss(animated: true)
            }
        }
    }

    private func updateDataImage() {
        guard let encrypted = encryptImage() else {
            showAlert(title: "Error", message: "There was an error storing your image. Try again later.")
            return
        }
        DispatchQueue.main.async {
            DBManager.shared.saveEncryptedDataImage(
                nameOfData: self.titleTextField.text!.sanitizeNameForDB(),
                lnkData: encrypted,
                userID: self.user!.uid) { [weak self] success in
                guard let self = self, success else { return }
                self.showAlert(title: "Updated", message: "Your image has been updated.") {
                    self.dismiss(animated: true)
                }
            }
        }
    }

    private func loadEncryptedData() {
        DBManager.shared.downloadData(for: user!.uid, nameOfData: nameData) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let encryptedData):
                var image = Encryption.shared.decryptImage(data: encryptedData, lengthKey: 10)
                if image == nil { image = UIImage(named: "LogoIcon") }
                DispatchQueue.main.async { self.imageView.image = image }
            case .failure:
                self.showAlert(title: "Error", message: "There was an error downloading your image. Try again later.")
            }
        }
    }

    // MARK: — Validation

    private func verifyFields() -> Bool {
        if titleTextField.text?.isEmpty == true {
            showAlert(title: "Missing Title", message: "Please give this image a title.")
            return false
        }
        return true
    }

    // MARK: — Encryption

    private func encryptImage() -> Data? {
        let image = imageView.image ?? UIImage(named: "LogoIcon")!
        return Encryption.shared.encryptImage(oldImage: image, lengthKey: 10)
    }

    // MARK: — Alert helper

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

// MARK: — Image Picker

extension DataImageController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let selected = info[.editedImage] as? UIImage else { return }
        imageView.image = selected
    }

    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType  = .camera
        vc.delegate    = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }

    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType  = .photoLibrary
        vc.delegate    = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
}
