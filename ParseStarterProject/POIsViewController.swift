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

// create alert message if data doesn't load

class POIsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate, POIDataSentDelegate, MapClickedDelegate {
    
    var unsortedNameArray = [String]()
    var nameArray = [String]()
    var distanceArray = [String]()
    var unsortedDistanceArray = [String]()
    var coordinatesArray = [CLLocationCoordinate2D]()
    var completedArray = [String]()
    var unsortedCategoryArray = [String]()
    var categoryArray = [String]()
    var imageDataArray = [PFFile]()
    var unsortedImageDataArray = [PFFile]()
    var sortingWithDistanceArray = [Double]()
    var unsortedAreaArray = [String]()
    var areaArray = [String]()
    
    let searchController = UISearchController(searchResultsController: nil)
    var filteredNameArray = [String]()
    var activityIndicator = UIActivityIndicatorView()
    var userLocation = CLLocationCoordinate2D()
    var email: String?
    var scrollView = UIScrollView()
    var chosenPOI = String()
    var areasChosenMain = ["Kensington and Chelsea"]
    var categoriesChosenMain = [String]()
    
    @IBOutlet var tableView: UITableView!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar

        getStarterVariables { (Bool) in
            self.fetchData { (Bool) in
                self.distanceOrder(completion: { (Bool) in
                    self.parseFetchImages()
                })
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        
        // Aesthetics
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont(name: "AvenirNext-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20), NSForegroundColorAttributeName: UIColor.white]
        view.backgroundColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        navigationController?.navigationBar.barTintColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.isHidden = false
      
    }
    
    // Functions

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchController.searchBar.endEditing(true)
        return true
    }
    
    func getStarterVariables(completion: @escaping (_ result: Bool)->()) {
        if let tempEmail = PFUser.current()?.username! {
            self.email = tempEmail
        }
        
        unsortedNameArray.removeAll()
        distanceArray.removeAll()
        coordinatesArray.removeAll()
        completedArray.removeAll()
        unsortedCategoryArray.removeAll()
        categoryArray.removeAll()
        unsortedImageDataArray.removeAll()
        imageDataArray.removeAll()
        sortingWithDistanceArray.removeAll()
        filteredNameArray.removeAll()

        if let tempGeoPoint = PFUser.current()?["location"] as? PFGeoPoint {
            self.userLocation = CLLocationCoordinate2D(latitude: tempGeoPoint.latitude, longitude: tempGeoPoint.longitude)
            print(self.userLocation)
            completion(true)
            
        }
        print("loading POISVC")
        print(userLocation)
    }

    
    func fetchData(completion: @escaping (_ result: Bool)->()) {
        let query = PFQuery(className: "POI")
        if areasChosenMain != [] {
            query.whereKey("area", containedIn: areasChosenMain)
        }
        if categoriesChosenMain != [] {
            query.whereKey("Category", containedIn: categoriesChosenMain)
        }
        
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        if let tempCoordinates = object["coordinates"] as? PFGeoPoint {
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: tempCoordinates.latitude, longitude: tempCoordinates.longitude))
                            if self.userLocation.latitude > 0 {
                                let tempUserLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                let tempPOILocation = CLLocation(latitude: tempCoordinates.latitude, longitude: tempCoordinates.longitude)
                                let tempDistance = round(Double(tempUserLocation.distance(from: tempPOILocation) / 1000) * 100) / 100
                                self.unsortedDistanceArray.append(String(tempDistance))
                                self.sortingWithDistanceArray.append(tempDistance)
                            }
                            
                        } else {
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0))
                            self.unsortedDistanceArray.append("0")
                            self.sortingWithDistanceArray.append(0)
                        }
                        if let tempName = object["name"] as? String {
                            self.unsortedNameArray.append(tempName)
                        } else {
                            self.unsortedNameArray.append("not found")
                        }
                        if let tempCategory = object["Category"] as? String {
                            self.unsortedCategoryArray.append(tempCategory)
                        } else {
                            self.unsortedCategoryArray.append("Other")
                        }
                        if let tempArea = object["area"] as? String {
                            self.unsortedAreaArray.append(tempArea)
                        } else {
                            self.unsortedAreaArray.append("")
                        }
                        if let tempPic = object["smallPicture"] as? PFFile {
                            self.unsortedImageDataArray.append(tempPic)
                        } else {
                            self.unsortedImageDataArray.append(PFFile(data: UIImageJPEGRepresentation(UIImage(named: "NA.png")!, 0.1)!)!)
                        }
                        i += 1
                        if i == objects.count {
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    func distanceOrder(completion: (_ result: Bool)->()) {

        var i = 0
        self.completedArray.removeAll()
        // category and area
        
        let sortedDistanceArray = sortingWithDistanceArray.sorted()
        categoryArray = unsortedCategoryArray
        areaArray = unsortedAreaArray
        nameArray = unsortedNameArray
        distanceArray = unsortedDistanceArray
        imageDataArray = unsortedImageDataArray
        var j = 0
        for distanceItem in sortingWithDistanceArray {
            let indexNo = sortedDistanceArray.index(of: distanceItem)
            categoryArray[indexNo!] = unsortedCategoryArray[sortingWithDistanceArray.index(of: distanceItem)!]
            areaArray[indexNo!] = unsortedAreaArray[sortingWithDistanceArray.index(of: distanceItem)!]
            nameArray[indexNo!] = unsortedNameArray[sortingWithDistanceArray.index(of: distanceItem)!]
            distanceArray[indexNo!] = unsortedDistanceArray[sortingWithDistanceArray.index(of: distanceItem)!]
            imageDataArray[indexNo!] = unsortedImageDataArray[sortingWithDistanceArray.index(of: distanceItem)!]
            j += 1
            if j == sortingWithDistanceArray.count {
                print("sorting finished")
                i += 1
            }
        }
        
        // image and completed
        
        let imageFiller = UIImage(named: "NA.png")
        let imageFillerData = UIImageJPEGRepresentation(imageFiller!, 0.1)

        for _ in self.nameArray {
            self.completedArray.append("no")
           // self.imageDataArray.append(PFFile(data: imageFillerData!)!)
            if self.imageDataArray.count == self.nameArray.count {
               /// i += 1
            }
        }

        if i == 1 {
            completion(true)
            print("distance done")
        }
    }
    
    
    func parseFetchImages() {
        // Get Parse images and completed
        let queryRest = PFQuery(className: "POI")
        if areasChosenMain != [] {
            queryRest.whereKey("area", containedIn: areasChosenMain)
        } else {
            queryRest.whereKey("area", notEqualTo: "")
        }
        if categoriesChosenMain != [] {
            queryRest.whereKey("Category", containedIn: categoriesChosenMain)
        }
        queryRest.findObjectsInBackground { (objects, error) in
            if let objects = objects {
                for object in objects {
                    if let tempName = object["name"] as? String {
                        if let indexCheck = self.nameArray.index(of: tempName) {
                            // add photo to all POIs
                            if let photo = object["smallPicture"] as? PFFile {
                               // self.imageDataArray[indexCheck] = photo
                            }
                            if let tempCompletedArray = object["completed"] as? [String] {
                                if tempCompletedArray.contains(self.email!) {
                                    self.completedArray[indexCheck] = "yes"
                                }
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
    
    func localData() {
        
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredNameArray = nameArray.filter({ (skill) -> Bool in
            return skill.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    // Table
    
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
            if categoryArray != [] {
                cell.locationCategory.text = "\(areaArray[indexValue!]), \(categoryArray[indexValue!])"  }

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
            if categoryArray != [] {
                cell.locationCategory.text = "\(areaArray[indexPath.row]), \(categoryArray[indexPath.row])"
            }

            // picture
            cell.tag = indexPath.row
            if imageDataArray != [] {
                imageDataArray[indexPath.row].getDataInBackground { (data, error) in
                    
                    if let imageData = data {
                        if let downloadedImage = UIImage(data: imageData) {
                            DispatchQueue.main.async {
                                if cell.tag == indexPath.row {
                                    cell.locationImage.image = downloadedImage
                                } else {
                                    cell.locationImage.image = UIImage()
                                }
                            }
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
        
        print("name \(nameArray[indexPath.row])")
            
        performSegue(withIdentifier: "toSinglePOI", sender: self)
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
 
    // Delegate Functions
    
    func userSelectedData(areasChosen: [String], categoriesChosen: [String]) {
        areasChosenMain = areasChosen
        categoriesChosenMain = categoriesChosen
        print(areasChosenMain)
        print(categoriesChosenMain)
        
        // reload table function:
        getStarterVariables { (Bool) in
            self.fetchData { (Bool) in
                self.distanceOrder(completion: { (Bool) in
                    self.parseFetchImages()
                })
            }
        }
        
    }
    
    func mapClicked(data: Bool) {
        if data == true {
            tabBarController?.selectedIndex = 0
        }
        
    }
    
    // Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if (segue.identifier == "toSinglePOI") {
            let singlePOI = segue.destination as? SinglePOIViewController
            singlePOI?.name = chosenPOI
            singlePOI?.delegate = self
            
        }
        
        if segue.identifier == "cityPopover" {
            
            let popoverVC: CityPopOverViewController = segue.destination as! CityPopOverViewController
            popoverVC.baseView = "POIView"
            popoverVC.delegatePOI = self
            popoverVC.categoriesChosen = categoriesChosenMain
            popoverVC.areasChosen = areasChosenMain
            
            popoverVC.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverVC.popoverPresentationController!.delegate = self
            popoverVC.preferredContentSize = CGSize(width: UIScreen.main.bounds.width / 1.5, height: 150)
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}


extension POIsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
