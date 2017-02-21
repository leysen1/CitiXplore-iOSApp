//
//  ExploreFilterTableViewCell.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 12/02/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit

class ExploreFilterTableViewCell: UITableViewCell {


    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        nameLabel.layer.cornerRadius = 10
        nameLabel.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        nameLabel.backgroundColor = UIColor(red: 80/255,  green: 148/255, blue: 230/255, alpha: 1.0)
        nameLabel.textColor = UIColor.white
    }

}
