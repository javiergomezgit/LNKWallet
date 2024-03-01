//
//  DatasViewCell.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 11/26/21.
//

import UIKit

class DatasViewCell: UITableViewCell {

    @IBOutlet weak var nameOfDataLabel: UILabel!
    @IBOutlet weak var dataImage: UIImageView!
    @IBOutlet weak var passwordImage: UIImageView!
    @IBOutlet weak var secureNoteImage: UIImageView!
    @IBOutlet weak var imageImage: UIImageView!
    
    static let identifier = "DatasViewCell"

    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public func configure(model: LNKData) {
        
        self.nameOfDataLabel.text = model.nameData
        if model.typeData == "type_1" {
            dataImage.isHidden = false
            passwordImage.isHidden = true
            secureNoteImage.isHidden = true
            imageImage.isHidden = true
        } else if model.typeData == "type_2" {
            passwordImage.isHidden = false
            dataImage.isHidden = true
            secureNoteImage.isHidden = true
            imageImage.isHidden = true
        } else if model.typeData == "type_4" {
            secureNoteImage.isHidden = true
            passwordImage.isHidden = true
            dataImage.isHidden = true
            imageImage.isHidden = false
        } else {
            secureNoteImage.isHidden = false
            passwordImage.isHidden = true
            dataImage.isHidden = true
            imageImage.isHidden = true
        }
    }
    
}



