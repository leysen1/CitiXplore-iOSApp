//
//  CityPopOverViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 30/01/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import CoreData

class CityPopOverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let moc = DataController().managedObjectContext
    
    var cities = ["London", "New York"]
    var chosenCity = String()
    
    @IBAction func retrieveCore(_ sender: Any) {
        
        let cityFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "City")
        
        do {
            let fetchedCities = try moc.fetch(cityFetch) as! [City]
            if fetchedCities.count > 0 {
                // change previously saved location
                for city in fetchedCities {
                    if let tempCity = city.value(forKey: "name") as? String {
                        print(tempCity)
                    }

                }
            }
        } catch {
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func savedData() {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        cell.textLabel?.text  = cities[indexPath.row]
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenCity = cities[indexPath.row]
        let cityFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "City")
        
        do {
            let fetchedCities = try moc.fetch(cityFetch) as! [City]
            if fetchedCities.count > 0 {
                // change previously saved location
                for city in fetchedCities {
                    if (city.value(forKey: "name") as? String) != nil {
                        city.setValue(cities[indexPath.row], forKey: "name")
                        do {
                            try moc.save()
                            print("updated location")
                        } catch { print("error") }
                    }
                }
            } else {
                // add first saved location
                let entity = NSEntityDescription.insertNewObject(forEntityName: "City", into: self.moc) as! City
                entity.setValue(cities[indexPath.row], forKey: "name")
                do {
                    try self.moc.save()
                    print("saved first location")
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
            }
        } catch {
            
        }

     
        
    }
    


}
