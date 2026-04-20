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

        navigationItem.rightBarButtonItem?.title = nameData.isEmpty ? "button.save".localized() : "button.update".localized()
        self.title = nameData.isEmpty ? "dataimage.title.new".localized() : "dataimage.title".localized()

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

        let saveBtn = UIBarButtonItem(title: "button.save".localized(),
                                     style: .done,
                                     target: self,
                                     action: #selector(saveButtonTapped))
        saveBtn.tintColor = .accentImages
        navigationItem.rightBarButtonItem = saveBtn
    }

    private func setupFields() {
        styleTextField(titleTextField, placeholder: "dataimage.placeholder.title".localized(), accent: .accentImages)

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
            showAlert(title: "alert.error.title".localized(), message: "alert.error.store_image.message".localized())
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
            showAlert(title: "alert.error.title".localized(), message: "alert.error.store_image.message".localized())
            return
        }
        DispatchQueue.main.async {
            DBManager.shared.saveEncryptedDataImage(
                nameOfData: self.titleTextField.text!.sanitizeNameForDB(),
                lnkData: encrypted,
                userID: self.user!.uid) { [weak self] success in
                guard let self = self, success else { return }
                self.showAlert(title: "alert.updated.title".localized(), message: "dataimage.updated.message".localized()) {
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
                self.showAlert(title: "alert.error.title".localized(), message: "alert.error.download_image.message".localized())
            }
        }
    }

    // MARK: — Validation

    private func verifyFields() -> Bool {
        if titleTextField.text?.isEmpty == true {
            showAlert(title: "alert.missing_title.title".localized(), message: "alert.missing_title.image.message".localized())
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
        alert.addAction(UIAlertAction(title: "button.ok".localized(), style: .default) { _ in completion?() })
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
