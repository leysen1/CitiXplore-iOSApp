//
//  AreaTableViewCell.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 17/10/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit

class AreaTableViewCell: UITableViewCell {

    @IBOutlet var areaLabel: UILabel!
    @IBOutlet var completedRatio: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
