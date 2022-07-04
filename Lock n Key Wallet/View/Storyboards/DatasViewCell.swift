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
            passwordImage.isHidden = true
            dataImage.isHidden = false
        } else {
            dataImage.isHidden = true
            passwordImage.isHidden = false
        }
    }
    
}



