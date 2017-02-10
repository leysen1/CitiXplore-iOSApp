//
//  SecondCityPopoverViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 09/02/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse

class SecondCityPopoverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var city = "London"
    var areaArray = [String]()
    var categoryArray = [String]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
    }
    
    func fetchData() {
        
        let query = PFQuery(className: "POI")
        query.whereKey("city", equalTo: city)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    for object in objects {
                        
                    }
                }
            }
        }
        
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        cell.textLabel?.text = "Test"
        return cell
    }

}
