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
    @IBOutlet var locationDistance: UILabel!
    @IBOutlet var locationImage: UIImageView!

    @IBOutlet var tickImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        locationImage.layer.cornerRadius = 10
        locationImage.layer.masksToBounds = true
        
        
        let tickShape = CAShapeLayer()
        tickShape.bounds = tickImage.frame
        tickShape.position = tickImage.center
        tickShape.path = UIBezierPath(roundedRect: tickImage.bounds, byRoundingCorners: .topRight, cornerRadii: CGSize(width: 5, height: 5)).cgPath
        tickImage.layer.addSublayer(tickShape)
        tickImage.layer.backgroundColor = UIColor.clear.cgColor
        tickImage.layer.mask = tickShape
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
