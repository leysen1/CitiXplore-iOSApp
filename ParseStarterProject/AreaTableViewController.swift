//
//  AreaTableViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 17/10/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse


class AreaTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var perAreaPOIs = [String: Int]()
    var allAreas = [String]()
    var completed = [String: Int]()
    var londonArray = [String]()
    var chosenArea = String()

    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let query = PFQuery(className: "POI")
        query.whereKey("city", equalTo: "London")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
            } else {
                
                // create an array of all the different areas in London
                
                if let POIs = objects {
                    self.allAreas.removeAll()
                    for POI in POIs {
                        let area = POI["area"] as! String
                        self.allAreas.append(area)
                        if self.londonArray.contains(area) {
                            // do nothing
                        } else {
                             self.londonArray.append(area)
                        }
            }
                    for item in self.allAreas {
                        self.perAreaPOIs[item] = (self.perAreaPOIs[item] ?? 0) + 1 }
                    print("perAreaPOIs")
                    print(self.perAreaPOIs)
                    print(self.londonArray)

                }
        }
    }

        let query2 = PFQuery(className: "POI")
        query2.whereKey("city", equalTo: "London")
        query2.whereKey("completed", contains: PFUser.current()?.username!)
        query2.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
            } else {
                self.allAreas.removeAll()
                // create array of user's completed POIS
                if let POIs = objects {
                    for POI in POIs {
                        let area = POI["area"] as! String
                        self.allAreas.append(area)
                    }
                    
                    for item in self.allAreas {
                        self.completed[item] = (self.completed[item] ?? 0) + 1 }
                    print("completed POI")
                    print(self.completed)

                    self.tableView.reloadData()
                    self.tableView.tableFooterView = UIView()
                }
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if allAreas.count < 1 {
            tableView.reloadData()
        }
    }
    
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return londonArray.count
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AreaCell", for: indexPath) as! AreaTableViewCell
        cell.areaLabel.text = londonArray[indexPath.row]
        if let allInArea = perAreaPOIs[londonArray[indexPath.row]] {
            if let completedInArea = completed[londonArray[indexPath.row]] {
                cell.completedRatio.text = (String(completedInArea) + "/" + String(allInArea))
                if allInArea == completedInArea {
                    print("all done")
                    cell.backgroundColor = UIColor.groupTableViewBackground
                } else {
                    cell.backgroundColor = UIColor.clear
                }

            } else {
                cell.completedRatio.text = ("0/" + String(allInArea))
            }


        }
        
        

        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        if londonArray.count > 0 {
            chosenArea = londonArray[indexPath.row]
            performSegue(withIdentifier: "toPOIs", sender: self)
        }
    }
    
    @IBAction func mapView(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)

        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toPOIs") {
            
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            let POIVC = segue.destination as! POIsViewController
            POIVC.chosenAreaPOI = self.chosenArea
        }
    }
    
    
    
    @IBAction func logout(_ sender: AnyObject) {
        PFUser.logOut()
        print("logged out")
        dismiss(animated: true, completion: nil)

        
    }
    


    


    
 }
