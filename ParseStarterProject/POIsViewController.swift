//
//  POIsViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 12/10/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Parse
import CoreData

// create alert message if data doesn't load

class POIsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    let moc = DataController().managedObjectContext
    
    var nameArray = [String]()
    var coreDataNameArray = [String]()
    var nameArrayOutdated = [String]()
    var distanceArray = [String]()
    var coordinatesArray = [CLLocationCoordinate2D]()
    var completedArray = [String]()
    var imageDataArray = [PFFile]()
    var sortingWithDistanceArray = [Double]()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredNameArray = [String]()
    var chosenAreaPOI = ""
    var activityIndicator = UIActivityIndicatorView()
    var userLocation = CLLocationCoordinate2D()
    var email: String?
    var scrollView = UIScrollView()
    var chosenPOI = String()
    
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredNameArray = nameArray.filter({ (skill) -> Bool in
            return skill.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    @IBOutlet var tableView: UITableView!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("User email \(email)")
        
        self.title = chosenAreaPOI
        
        
 
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
 
        coreDataFetch { (Bool) in
            
            newParseFetchAndSave { (Bool) in
                print("completed Parse Fetch")
                
                self.distanceOrder { (Bool) in
                    print("completed distance Order")
                    self.fetchCompletedParse(completion: { (Bool) in
                        print("fetch completed done")
                        self.saveCompleted(completion: { (Bool) in
                            self.coreDataFetch2 { (Bool) in
                                self.ParseFetchImages()
                                print("completed array \(self.completedArray)")
                                // background running
                                
                                self.getOutdatedPOIs { (Bool) in
                                    self.deleteOutdatedPOIs()
                                }
                            }
                        })
                        
                    })
                    
                }
            }
        }
        
        
    }
    

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchController.searchBar.endEditing(true)
        return true
    }
    
    @available(iOS 9.0, *)
    func deleteSavedData(completion: (_ result: Bool)->()) {
        // Delete all saved CoreData
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "POI")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try moc.execute(batchDeleteRequest)
            completion(true)
            print("deleted all core data")
        } catch {
            // Error Handling
        }
    }
    
    
    
    func coreDataFetch(completion: (_ result: Bool)->()) {
        self.nameArray.removeAll()
        self.coreDataNameArray.removeAll()
        self.coordinatesArray.removeAll()
        self.distanceArray.removeAll()
        self.sortingWithDistanceArray.removeAll()
        self.completedArray.removeAll()
        self.imageDataArray.removeAll()
        
        print("removed arrays")
        
        // 1. get saved data - name and coords
        let poiFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "POI")
        poiFetch.predicate = NSPredicate(format: "area = %@", chosenAreaPOI)
        
        do {
            let fetchedPOIs = try moc.fetch(poiFetch) as! [POI]
            if fetchedPOIs.count > 0 {
                var i = 0
                print("\(fetchedPOIs.count) objects found in core")
                for poi in fetchedPOIs {
                    if let tempName = poi.value(forKey: "name") as? String {
                        nameArray.append(tempName)
                        coreDataNameArray.append(tempName)
                    }
                    if let tempLatitude = poi.value(forKey: "latitude") as? Double {
                        if let tempLongitude = poi.value(forKey: "longitude") as? Double {
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: tempLatitude, longitude: tempLongitude))
                            if self.userLocation.latitude > 0 {
                                let tempUserLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                let tempPOILocation = CLLocation(latitude: tempLatitude, longitude: tempLongitude)
                                let distance = Double(tempUserLocation.distance(from: tempPOILocation) / 1000)
                                self.distanceArray.append(String(distance))
                                self.sortingWithDistanceArray.append(distance)
                            }
                        }
                    }
                    i += 1
                    if i == fetchedPOIs.count {
                        completion(true)
                        print("completed")
                    }
                }
            } else {
                completion(true)
                print("no objects found saved in core")
            }
        } catch {
            fatalError("Failed to fetch POI: \(error)")
        }
    }
    
    
    func newParseFetchAndSave(completion: @escaping (_ result: Bool)->()) {
        // 2. get new data from parse and save to core data - names and coords
        let queryName = PFQuery(className: "POI")
        queryName.whereKey("area", equalTo: self.chosenAreaPOI)
        queryName.whereKey("name", notContainedIn: self.nameArray)
        queryName.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
                print("error - no objects found")
            } else {
                if let objects = objects {
                    if objects.count > 0 {
                        var i = 0
                        print("\(objects.count) new objects found")
                        for object in objects {
                            let entity = NSEntityDescription.insertNewObject(forEntityName: "POI", into: self.moc) as! POI
                            // get the POI distances from user location
                            if let POILocation = object["coordinates"] as? PFGeoPoint {
                                self.coordinatesArray.append(CLLocationCoordinate2D(latitude: POILocation.latitude, longitude: POILocation.longitude))
                                entity.setValue(POILocation.latitude, forKey: "latitude")
                                entity.setValue(POILocation.longitude, forKey: "longitude")
                                if self.userLocation.latitude > 0 {
                                    let tempUserLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                    let tempPOILocation = CLLocation(latitude: POILocation.latitude, longitude: POILocation.longitude)
                                    let distance = Double(tempUserLocation.distance(from: tempPOILocation) / 1000)
                                    self.distanceArray.append(String(distance))
                                    self.sortingWithDistanceArray.append(distance)
                                }
                                // get new POI data and save to core
                                if let nameTemp = object["name"] as? String {
                                    self.nameArray.append(nameTemp)
                                    entity.setValue(nameTemp, forKey: "name")
                                }
                                if let areaTemp = object["area"] as? String {
                                    entity.setValue(areaTemp, forKey: "area")
                                }
                                if let completedTemp = object["completed"] as? [String] {
                                    if let emailTemp = self.email {
                                        if completedTemp.contains(emailTemp) {
                                            entity.setValue("yes", forKey: "completed")
                                        } else {
                                            entity.setValue("no", forKey: "completed")
                                        }
                                    }
                                }
                            } else {
                                print("Could not get POI Location")
                            }
                            
                            do {
                                try self.moc.save()
                            } catch {
                                fatalError("Failure to save context: \(error)")
                            }
                            i += 1
                            if i == objects.count {
                                completion(true)
                            }
                        }
                    } else {
                        print("no objects found as count = 0")
                        completion(true)
                    }
                } else {
                    completion(true)
                }
            }
        }
    }
    
    
    // see here - add in a deletion of completion
    var parseFetchCompleted = [String]()
    
    func fetchCompletedParse(completion: @escaping (_ result: Bool)->()) {
        parseFetchCompleted.removeAll()
        let query = PFQuery(className: "POI")
        query.whereKey("area", equalTo: self.chosenAreaPOI)
        query.whereKey("completed", contains: email)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                
            } else {
                if let objects = objects {
                    print("found objects")
                    var i = 0
                    if objects.count > 0 {
                        for object in objects {
                            if let nameTemp = object["name"] as? String {
                                self.parseFetchCompleted.append(nameTemp)
                            }
                            i += 1
                            if i == objects.count {
                                completion(true)
                            }
                        }
                    } else {
                        completion(true)
                    }
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func saveCompleted(completion: @escaping (_ result: Bool)->()) {
        var i = 0
        if parseFetchCompleted.count > 0 {
            for item in parseFetchCompleted {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "POI")
                request.predicate = NSPredicate(format: "name = %@", item)
                request.returnsObjectsAsFaults = false
                
                do {
                    let fetchedPOIs = try moc.fetch(request) as! [POI]
                    if fetchedPOIs.count > 0 {
                        for poi in fetchedPOIs {
                            poi.setValue("yes", forKey: "completed")
                            do {
                                try moc.save()
                            } catch { print("error") }
                        }
                    }
                } catch {
                    print(error)
                }
                i += 1
                if i == parseFetchCompleted.count {
                    completion(true)
                }
            }
        } else {
            completion(true)
        }
    }
    
    func distanceOrder(completion: (_ result: Bool)->()) {
        // create dictionary out of name array and distance
        print("distance array \(self.distanceArray.count)")
        print("sorting distance array \(self.sortingWithDistanceArray.count)")
        print("name array \(self.nameArray.count)")
        var i = 0
        if sortingWithDistanceArray.count == distanceArray.count && nameArray.count == sortingWithDistanceArray.count {
            
            var dictName: [String: Double] = [:]
            var dictDist: [String: Double] = [:]
            
            for (name, number) in self.nameArray.enumerated() {
                dictName[number] = self.sortingWithDistanceArray[name]
            }
            for (distance, number) in self.distanceArray.enumerated() {
                dictDist[number] = self.sortingWithDistanceArray[distance]
            }
            
            let sortedName = (dictName as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
            let sortedDist = (dictDist as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
            
            self.nameArray = sortedName as! [String]
            self.distanceArray = sortedDist as! [String]
            
            var tempDistanceArray = [String]()
            tempDistanceArray.removeAll()
            for item in self.distanceArray {
                let number: Double = round(Double(item)! * 100) / 100
                tempDistanceArray.append(String(number))
                if tempDistanceArray.count == distanceArray.count {
                    i += 1
                }
            }
            self.distanceArray = tempDistanceArray
            
        }
        
        // prepare for other information in getData function
        self.completedArray.removeAll()
        self.imageDataArray.removeAll()
        
        let imageFiller = UIImage(named: "NA.png")
        let imageFillerData = UIImageJPEGRepresentation(imageFiller!, 1.0)
        
        for _ in self.nameArray {
            self.completedArray.append("no")
            self.imageDataArray.append(PFFile(data: imageFillerData!)!)
            if self.imageDataArray.count == self.nameArray.count {
                i += 1
            }
        }
        if i == 2 {
            completion(true)
            print("distance done")
        }
    }
    
    
    func coreDataFetch2(completion: (_ result: Bool)->()) {
        // Get all address and completed in right order
        let poiFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "POI")
        if self.completedArray.count == self.nameArray.count {
            print("completed array ARE ready")
            var i = 0
            for name in self.nameArray {
                poiFetch.predicate = NSPredicate(format: "name = %@", name)
                poiFetch.returnsObjectsAsFaults = false
                do {
                    let results = try self.moc.fetch(poiFetch)
                    if results.count > 0 {
                        for result in results {
                                if let indexNumber = self.nameArray.index(of: name) {
                                    if let tempCompleted = (result as AnyObject).value(forKey: "completed") {
                                        self.completedArray[indexNumber] = (tempCompleted as? String)!
                                    }
                            }
                            i += 1
                            if i == nameArray.count {
                                print("completed as i = \(i)")
                                completion(true)
                            }
                        }
                    }
                } catch {
                    print("failed to fetch result")
                }
            }
        } else {
            print("completed array were not ready")
        }
    }
    
    func ParseFetchImages() {
        // Get Parse images
        let queryRest = PFQuery(className: "POI")
        queryRest.whereKey("area", equalTo: self.chosenAreaPOI)
        queryRest.findObjectsInBackground { (objects, error) in
            if let objects = objects {
                for object in objects {
                    if let tempName = object["name"] as? String {
                        if let indexCheck = self.nameArray.index(of: tempName) {
                            // add photo to all POIs
                            if let photo = object["smallPicture"] as? PFFile {
                                self.imageDataArray[indexCheck] = photo
                            }
                        }
                    }
                    self.tableView.reloadData()
                }
                self.tableView.reloadData()
                self.tableView.tableFooterView = UIView()
            }
        }
    }
    
    func getOutdatedPOIs(completion: @escaping (_ result: Bool)->()) {
        nameArrayOutdated = self.nameArray
        let query = PFQuery(className: "POI")
        query.whereKey("area", equalTo: self.chosenAreaPOI)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        if let tempName = object["name"] as? String  {
                            if self.nameArrayOutdated.contains(tempName) {
                                if let indexNo = self.nameArrayOutdated.index(of: tempName) {
                                    self.nameArrayOutdated.remove(at: indexNo)
                                }
                            }
                        }
                        i += 1
                        if i == objects.count {
                            print("outdated array \(self.nameArrayOutdated)")
                            completion(true)
                        }
                    }
                    
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func deleteOutdatedPOIs() {
        if nameArrayOutdated.count > 0 {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "POI")
            request.predicate = NSPredicate(format: "name = %@", argumentArray: nameArrayOutdated)
            request.returnsObjectsAsFaults = false
            do {
                let results = try moc.fetch(request)
                for result in results as! [NSManagedObject] {
                    self.moc.delete(result)
                    
                    do {
                        try self.moc.save()
                        print("delete saved")
                    } catch { print("delete failed")
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // add in search count
        
        if completedArray.count > 0 && imageDataArray.count > 0 {
            if searchController.isActive && searchController.searchBar.text != "" {
                return filteredNameArray.count
            }
            
            return nameArray.count
        } else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! POIsTableViewCell
        
        
        if searchController.isActive && searchController.searchBar.text != "" {
            let indexValue = nameArray.index(of: filteredNameArray[indexPath.row])
            // name
            if nameArray != [] {
                cell.locationName.text = filteredNameArray[indexPath.row] }
            if distanceArray != [] {
                cell.locationDistance.text = "\(distanceArray[indexValue!]) km" }
            
            // picture
            if imageDataArray != [] {
                imageDataArray[indexValue!].getDataInBackground { (data, error) in
                    
                    if let imageData = data {
                        if let downloadedImage = UIImage(data: imageData) {
                            cell.locationImage.image = downloadedImage
                        }
                    }
                }
            }
            
            if completedArray[indexValue!] == "yes" {
                cell.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1.0)
                cell.locationName.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage(named: "tick.png")
            } else {

                cell.backgroundColor = UIColor.clear
                cell.locationName.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage()
                
            }
            
        } else {
            // no filter
            
            // name
            if nameArray != [] {
                cell.locationName.text = nameArray[indexPath.row] }
            if distanceArray != [] {
                cell.locationDistance.text = "\(distanceArray[indexPath.row]) km" }
            
            // picture
            if imageDataArray != [] {
                imageDataArray[indexPath.row].getDataInBackground { (data, error) in
                    
                    if let imageData = data {
                        if let downloadedImage = UIImage(data: imageData) {
                            cell.locationImage.image = downloadedImage
                        }
                    }
                }
            }
            
            if completedArray[indexPath.row] == "yes" {
                cell.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1.0)
                cell.locationName.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage(named: "tick.png")
            } else {

                cell.backgroundColor = UIColor.clear
                cell.locationName.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage()
            }
        }
        
        // return
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            chosenPOI = filteredNameArray[indexPath.row]
        } else {
             chosenPOI = nameArray[indexPath.row]
        }
        
            
        performSegue(withIdentifier: "toSinglePOI", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toSinglePOI") {
            let singlePOI = segue.destination as! SinglePOIViewController
            singlePOI.name = chosenPOI
            singlePOI.hidesBottomBarWhenPushed = true
            
        }
    }

}


extension POIsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
