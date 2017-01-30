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
    var areaImageDic = [String: PFFile]()
    var imageArray = [PFFile]()
    var londonArray = [String]()
    var chosenArea = String()
    var userLocation = CLLocationCoordinate2D()
    var email = String()

    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
       
        totalPOI()
        completedPOI()
        fetchAreaImages { (Bool) in
            print("completed image fetch")
            self.sortAreaImages()
        }
        self.tableView.separatorStyle = .none
 
    }
    
    func totalPOI() {
        let query = PFQuery(className: "POI")
        query.whereKey("city", equalTo: "London")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
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
                    self.londonArray.sort()
                    for item in self.allAreas {
                        self.perAreaPOIs[item] = (self.perAreaPOIs[item] ?? 0) + 1 }
                    self.tableView.reloadData()
                    self.tableView.tableFooterView = UIView()
                    
                }
            }
        }

    }
    
    func completedPOI() {
        let query2 = PFQuery(className: "POI")
        query2.whereKey("city", equalTo: "London")
        query2.whereKey("completed", contains: email)
        query2.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
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
                    
                    self.tableView.reloadData()
                    self.tableView.tableFooterView = UIView()
                }
            }
        }
        
    }
    
    func fetchAreaImages(completion: @escaping (_ result: Bool)->()) {
        
        let query = PFQuery(className: "Area")
        query.whereKey("city", equalTo: "London")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        
                        if let tempName = object["name"] as? String {
                                // add photo to all POIs
                                if let photo = object["picture"] as? PFFile {
                                    self.areaImageDic[tempName] = photo
                                    i += 1
                                    if i == objects.count {
                                        completion(true)
                                    }
                            }
                        }
                        
                        
                    }
                }
            }
        }
        
    }
    
    func sortAreaImages() {
        
        print("sorting")
        let sortedImages = areaImageDic.sorted{ $0.key < $1.key }
        print(sortedImages)
        
        let values = sortedImages.map {return $0.1 }
        self.imageArray = values
        print(values)
        self.tableView.reloadData()
        self.tableView.tableFooterView = UIView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if allAreas.count < 1 {
            tableView.reloadData()
        }
        
        navigationController?.navigationBar.barTintColor = UIColor.white
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
            if imageArray != [] {
                imageArray[indexPath.row].getDataInBackground { (data, error) in
                    
                    if let imageData = data {
                        if let downloadedImage = UIImage(data: imageData) {
                            cell.backImageView.image = downloadedImage
                        }
                    }
                }
            }
        
        

        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        if londonArray.count > 0 {
            if userLocation.latitude != 0 {
                chosenArea = londonArray[indexPath.row]
                performSegue(withIdentifier: "toPOIs", sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toPOIs") {
            print("segue to POI")
            let backItem = UIBarButtonItem()
            backItem.title = "London"
            navigationItem.backBarButtonItem = backItem
 
            let POIVC = segue.destination as! POIsViewController
            POIVC.chosenAreaPOI = self.chosenArea
            POIVC.userLocation = self.userLocation
            POIVC.email = self.email


        }
    }
    

    


    


    
 }
