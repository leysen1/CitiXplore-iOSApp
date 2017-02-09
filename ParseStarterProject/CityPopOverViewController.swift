//
//  CityPopOverViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 30/01/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import CoreData
import Parse

protocol DataSentDelegate {
    func userSelectedData(data: String)
}

class CityPopOverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var delegate: DataSentDelegate? = nil
    let moc = DataController().managedObjectContext
    var baseView = ""
    var cities = ["London", "New York"]
    var areas = [String]()
    var chosenCity = String()
    

    @IBOutlet weak var tableViewPopOver: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSize(width: UIScreen.main.bounds.width / 1.5, height: 150)
        print(baseView)
        
        let query = PFQuery(className: "Area")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    for object in objects {
                        if let areaTemp = object["name"] as? String {
                            if areaTemp != "" {
                                self.areas.append(areaTemp)
                            }
                        }
                        self.tableViewPopOver.reloadData()
                    }
                }
            }
        }
        
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if baseView == "POIView" {
            return areas.count
        }
        if baseView == "RatingsView" {
            return areas.count
        } else {
            return 0
        }
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        if baseView == "POIView" {
            cell.textLabel?.text  = areas[indexPath.row]
        }
        if baseView == "RatingsView" {
            cell.textLabel?.text = areas[indexPath.row]
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        chosenCity = areas[indexPath.row]

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Shortcuts")
        
            do {
                let shortcutData = try moc.fetch(request) as! [Shortcuts]
                if shortcutData.count > 0 {
                    // change previously saved location
                    for log in shortcutData {
                         if baseView == "POIView" {
                            if (log.value(forKey: "area") as? String) != nil {
                                let areaTemp = self.areas[indexPath.row]
                                log.setValue(areaTemp, forKey: "area")
                                do {
                                    try moc.save()
                                    print("updated location")
                                    
                                    if delegate != nil {
                                        delegate?.userSelectedData(data: areaTemp)
                                        self.dismiss(animated: true, completion: nil)
                                    }
                                    
                                } catch { print("catch - save error") }
                            }
                        }
                        if baseView == "RatingsView" {
                            if (log.value(forKey: "area") as? String) != nil  {
                                let areaTemp = self.areas[indexPath.row]
                                log.setValue(areaTemp, forKey: "area")
                                do {
                                    try moc.save()
                                    print("updated location")
                                    
                                    if delegate != nil {
                                            delegate?.userSelectedData(data: areaTemp)
                                            self.dismiss(animated: true, completion: nil)
                                    }
                                    
                                } catch { print("catch - save error") }
                            }
                        }
                    }
                } else {
                    print("no stored shortcut found")
                }
            } catch { print("catch - fetch error") }
    }


}





