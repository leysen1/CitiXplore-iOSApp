//
//  RatingsViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 30/01/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse

class RatingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let rankings = ["Must See","Worth a Visit when in the City","Worth a Visit when in the Area","Worth a detour","Interesting POI"]
    
    var rating1 = [String]()
    var rating2 = [String]()
    var rating3 = [String]()
    var rating4 = [String]()
    
    var data = [[String]]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchData { (Bool) in
            
            self.rating1.sort()
            self.rating2.sort()
            self.rating3.sort()
            self.rating4.sort()
            
            print("ratings \(self.rating1) \(self.rating2) \(self.rating3) \(self.rating4)")
            
            self.data.append(self.rating4)
            self.data.append(self.rating3)
            self.data.append(self.rating2)
            self.data.append(self.rating1)
            
            print("all in one")
            print(self.data)
            
            self.tableView.reloadData()
            
        }

    }
    
    func fetchData(completion: @escaping (_ result: Bool)->()) {
        
        let query = PFQuery(className: "POI")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        if let tempName = object["name"] as? String {
                            if let tempRating = object["ratings"] as? Int {
                                
                                switch tempRating {
                                case 1:
                                    self.rating1.append(tempName)
                                case 2:
                                    self.rating2.append(tempName)
                                case 3:
                                    self.rating3.append(tempName)
                                case 4:
                                    self.rating4.append(tempName)
                                default:
                                    break
                                }
                            }
                        }
                        i += 1
                        if objects.count == i {
                            completion(true)
                        }
                    }
            
                }
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return rankings[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        cell.textLabel?.text = data[indexPath.section][indexPath.row]
        return cell
        
    }
    


}
