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

class CityPopOverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let moc = DataController().managedObjectContext
    var baseView = ""
    
    var cities = ["London", "New York"]
    var areas = [String]()
    var chosenCity = String()
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func retrieveCore(_ sender: Any) {
        
        let cityFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Shortcuts")
        
        do {
            let fetchedCities = try moc.fetch(cityFetch) as! [Shortcuts]
            if fetchedCities.count > 0 {
                // change previously saved location
                for city in fetchedCities {
                    if let tempCity = city.value(forKey: "city") as? String {
                        print(tempCity)
                    }

                }
            }
        } catch {
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(baseView)
        
        let query = PFQuery(className: "Area")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    for object in objects {
                        if let areaTemp = object["name"] as? String {
                            self.areas.append(areaTemp)
                        }
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
    }
    
    func savedData() {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if baseView == "AreaView" {
            return cities.count
        }
        if baseView == "RatingsView" {
            return areas.count
        } else {
            return 0
        }
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        if baseView == "AreaView" {
            cell.textLabel?.text  = cities[indexPath.row]
        }
        if baseView == "RatingsView" {
            cell.textLabel?.text = areas[indexPath.row]
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenCity = cities[indexPath.row]
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Shortcuts")
        
       
            do {
                let shortcutData = try moc.fetch(request) as! [Shortcuts]
                if shortcutData.count > 0 {
                    // change previously saved location
                    for log in shortcutData {
                         if baseView == "AreaView" {
                            if (log.value(forKey: "city") as? String) != nil {
                                log.setValue(cities[indexPath.row], forKey: "city")
                                do {
                                    try moc.save()
                                    print("updated location")
                                } catch { print("catch - save error") }
                            }
                        }
                        if baseView == "RatingsView" {
                            if (log.value(forKey: "area") as? String) != nil {
                                log.setValue(areas[indexPath.row], forKey: "area")
                                do {
                                    try moc.save()
                                    print("updated location")
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
