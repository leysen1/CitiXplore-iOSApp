//
//  POIsTableViewCell.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 12/10/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit

class POIsTableViewCell: UITableViewCell {

    @IBOutlet var locationName: UILabel!
    @IBOutlet var locationAddress: UILabel!
    @IBOutlet var locationDistance: UILabel!
    @IBOutlet var locationImage: UIImageView!

    @IBOutlet var mapButton: UIButton!
    @IBOutlet var tickImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
