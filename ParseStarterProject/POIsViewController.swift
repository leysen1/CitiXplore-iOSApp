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

    var nameArray = [String]()
    var addressArray = [String]()
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
    var username: String?
    
    // audio Variables
    var audioArray = [AVAudioPlayer]()
    var trackPlaying = AVAudioPlayer()
    var playMode = false
    let serialQueue = DispatchQueue(label: "label")
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredNameArray = nameArray.filter({ (skill) -> Bool in
            return skill.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var scrubber: UISlider!
    @IBAction func scrubberChanged(_ sender: AnyObject) {
        trackPlaying.currentTime = TimeInterval(scrubber.value)
    }
    @IBOutlet var audioLocationName: UILabel!
    @IBOutlet var audioTimeLeft: UILabel!

    var timer = Timer()
    var time = Double()

    @IBOutlet var playButtonImage: UIButton!

    @IBAction func playPauseButton(_ sender: AnyObject) {

            if playMode == true {
                // pausing audio
                playButtonImage.setImage(UIImage(named: "play.jpg"), for: .normal)
                trackPlaying.pause()
                timer.invalidate()
                playMode = false
            } else {
                // playing audio
                playButtonImage.setImage(UIImage(named: "pause.jpg"), for: .normal)
                trackPlaying.play()
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
                playMode = true
            }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.playButtonImage.isEnabled = false
        self.scrubber.isEnabled = false
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
       
        
        if #available(iOS 10.0, *) {
            
            self.getPOINames(number: 30, completion: { (Bool) in
                print("address \(addressArray)")
                print("name \(nameArray)")
                self.getData()
            })
        }
        
    }


    override func viewDidAppear(_ animated: Bool) {
        
        if self.nameArray.count < 1 {
            self.tableView.reloadData()
        }
        
        

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchController.searchBar.endEditing(true)
        return true
    }

    
    @available(iOS 10.0, *)
    func getPOINames(number : Int, completion: (_ result: Bool)->()) {
        
        // 1. create table using saved data
        // 2. if there are new rows in parse then query and get those
        // 3. Sort in distance order
        // 4. Add new to the table
        
        self.nameArray.removeAll()
        self.coordinatesArray.removeAll()
        self.distanceArray.removeAll()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Name and Coordinates
        // 1. get saved data
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "POIs")
        request.predicate = NSPredicate(format: "area = %@", "Kensington and Chelsea")
        request.returnsObjectsAsFaults = false // to get the values of the data
        do {
            let results = try context.fetch(request)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let tempName = result.value(forKey: "name") as? String {
                        nameArray.append(tempName)
                    }
                    if let tempLatitude = result.value(forKey: "latitude") as? Double {
                        if let tempLongitude = result.value(forKey: "longitude") as? Double {
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
                }
                self.tableView.reloadData()
                print("nameCore \(self.nameArray)")
            } else {
                print("No results")
            }
        } catch {
            print("Couldn't fetch results")
        }
        
        // 2. get new data from parse and (save to core data)
        let queryName = PFQuery(className: "POI")
        queryName.whereKey("area", equalTo: self.chosenAreaPOI)
        queryName.whereKey("name", notContainedIn: self.nameArray)
        queryName.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
                print("no objects found")
            } else {
                if let objects = objects {
                    for object in objects {
                        // save object
                        let newPOI = NSEntityDescription.insertNewObject(forEntityName: "POIs", into: context)
                        
                        // get the POI distances from user location
                        if let POILocation = object["coordinates"] as? PFGeoPoint {
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: POILocation.latitude, longitude: POILocation.longitude))
                            newPOI.setValue(POILocation.latitude, forKey: "latitude")
                            newPOI.setValue(POILocation.longitude, forKey: "longitude")
                            
                            if self.userLocation.latitude > 0 {
                                let tempUserLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                let tempPOILocation = CLLocation(latitude: POILocation.latitude, longitude: POILocation.longitude)
                                let distance = Double(tempUserLocation.distance(from: tempPOILocation) / 1000)
                                self.distanceArray.append(String(distance))
                                self.sortingWithDistanceArray.append(distance)
                                
                                print("name \(self.nameArray)")
                                print("distance \(self.distanceArray)")
                            }
                            
                            if let nameTemp = object["name"] as? String {
                                self.nameArray.append(nameTemp)
                                newPOI.setValue(self.chosenAreaPOI, forKey: "area")
                                newPOI.setValue(nameTemp, forKey: "name")
                                if let addressTemp = object["address"] as? String {
                                    newPOI.setValue(addressTemp, forKey: "address")
                                    if let completedTemp = object["completed"] as? String {
                                        newPOI.setValue(completedTemp, forKey: "completed")
                                        do {
                                            try context.save()
                                            print("saved")
                                            
                                        } catch {
                                            print("There was an error")
                                        }
                                    }
                                }
                            }

                        } else {
                            print("Could not get POI Location")
                        }

                    }
                }
            }
        }
        
        // 3. sort in distance order

        // create dictionary out of name array and distance
        var dictName: [String: Double] = [:]
        var dictDist: [String: Double] = [:]
        
        for (name, number) in self.nameArray.enumerated()
        {
            dictName[number] = self.sortingWithDistanceArray[name]
        }
        for (distance, number) in self.distanceArray.enumerated()
        {
            dictDist[number] = self.sortingWithDistanceArray[distance]
        }
        
        let sortedName = (dictName as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
        let sortedDist = (dictDist as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
        
        self.nameArray = sortedName as! [String]
        self.distanceArray = sortedDist as! [String]

        var tempDistanceArray = [String]()
        for item in self.distanceArray {
            let number: Double = round(Double(item)! * 100) / 100
            tempDistanceArray.append(String(number))
        }
        self.distanceArray = tempDistanceArray
        
        self.tableView.reloadData()
        
        
        // prepare for other information in getData function
        self.addressArray.removeAll()
        self.completedArray.removeAll()
        self.imageDataArray.removeAll()
        
        let imageFiller = UIImage(named: "NA.png")
        let imageFillerData = UIImageJPEGRepresentation(imageFiller!, 1.0)
        
        for _ in self.nameArray {
            self.addressArray.append("address")
            self.completedArray.append("no")
            self.imageDataArray.append(PFFile(data: imageFillerData!)!)
            
            if number == addressArray.count  {
                completion(true)
            } else {
                completion(false)
            }
        }


    }
    
    @available(iOS 10.0, *)
    func getData() {
        
        // compeleted, address, and image

        // 1. Get completed and address data from core data
        // 2. Get completed and address data from parse
        // 3. Get all image data from Parse (small photos)
        
        // Core Data address and completed
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "POIs")
        request.predicate = NSPredicate(format: "area = %@", "Kensington and Chelsea")
        request.returnsObjectsAsFaults = false // to get the values of the data
        do {
            let results = try context.fetch(request)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let tempName = result.value(forKey: "name") as? String {
                        if self.addressArray.count > 1 {
                            if let tempAddress = result.value(forKey: "address") as? String {
                                self.addressArray[self.nameArray.index(of: tempName)!] = tempAddress
                            }
                        }
                        if self.completedArray.count > 1 {
                            if let tempCompleted = result.value(forKey: "completed") as? String {
                                self.completedArray[self.nameArray.index(of: tempName)!] = tempCompleted
                            }
                        }
                    }
                }
                self.tableView.reloadData()
            } else {
                print("No results")
            }
        } catch {
            print("Couldn't fetch results")
        }

        // Parse address, completed and images
        let queryRest = PFQuery(className: "POI")
        queryRest.whereKey("area", equalTo: self.chosenAreaPOI)
        queryRest.findObjectsInBackground { (objects, error) in
            if let objects = objects {
                
                for object in objects {
                    if let tempName = object["name"] as? String {
                        
                        // add photo to all POIs
                        if let photo = object["picture"] as? PFFile {
                            self.imageDataArray[(self.nameArray.index(of: tempName))!] = photo
                        }
                        // add address and completed to only new POIs
                        if self.nameArray.contains(tempName) == false {
                            if self.addressArray.count > 1 {
                                if let tempAddress = object["address"] as? String {
                                    self.addressArray[self.nameArray.index(of: tempName)!] = tempAddress
                                }
                            }
                            if self.completedArray.count > 1 {
                                if let tempCompleted = object["completed"] as? [String] {
                                    if self.username != nil {
                                        if tempCompleted.contains(self.username!) {
                                            self.completedArray[self.nameArray.index(of: tempName)!] = "yes"
                                        }
                                    }
                                }
                            }
                        }
                    }
                self.tableView.reloadData()
            }
                
            self.tableView.tableFooterView = UIView()
        }
    }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // add in search count
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredNameArray.count
        }

        return nameArray.count
    }

    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! POIsTableViewCell
        
        
        if searchController.isActive && searchController.searchBar.text != "" {
            let indexValue = nameArray.index(of: filteredNameArray[indexPath.row])
            // name and address
            if nameArray != [] {
                cell.locationName.text = filteredNameArray[indexPath.row] }
            if addressArray != [] {
                cell.locationAddress.text = addressArray[indexValue!] }
            if distanceArray != [] {
                cell.locationDistance.text = "You are \(distanceArray[indexValue!])km away" }
            
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
                cell.backgroundColor = UIColor.groupTableViewBackground
                cell.locationName.textColor = UIColor.black
                cell.locationAddress.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage(named: "tick.png")
            } else {
                cell.backgroundColor = UIColor.clear
                cell.locationName.textColor = UIColor.lightGray
                cell.locationAddress.textColor = UIColor.lightGray
                cell.locationDistance.textColor = UIColor.lightGray
                cell.locationImage.alpha = 0.5
                cell.tickImage.image = UIImage()
            }
            
        } else {
            // no filter
            
            // name and address
            if nameArray != [] {
                cell.locationName.text = nameArray[indexPath.row] }
            if addressArray != [] {
                cell.locationAddress.text = addressArray[indexPath.row] }
            if distanceArray != [] {
                cell.locationDistance.text = "You are \(distanceArray[indexPath.row])km away" }
            
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
                cell.backgroundColor = UIColor.groupTableViewBackground
                cell.locationName.textColor = UIColor.black
                cell.locationAddress.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage(named: "tick.png")
            } else {
                cell.backgroundColor = UIColor.clear
                cell.locationName.textColor = UIColor.lightGray
                cell.locationAddress.textColor = UIColor.lightGray
                cell.locationDistance.textColor = UIColor.lightGray
                cell.locationImage.alpha = 0.5
                cell.tickImage.image = UIImage()
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        cell.locationImage.addGestureRecognizer(tapGesture)
        cell.locationImage.isUserInteractionEnabled = true
        
        
        // return
        return cell
    }
      
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var tempPlayer = AVAudioPlayer()
        
        if nameArray.count > 0 {
            if self.playMode == true {
                self.trackPlaying.stop()
                self.playButtonImage.isEnabled = false
                self.scrubber.isEnabled = false
                self.playMode = false
                self.playButtonImage.setImage(UIImage(named: "play.jpg"), for: .normal)
            }
            
            //Spinner
            activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray   
            activityIndicator.startAnimating()
            UIApplication.shared.beginIgnoringInteractionEvents()
            view.addSubview(activityIndicator)
  
            let query = PFQuery(className: "POI")
            if searchController.isActive && searchController.searchBar.text != "" {
                query.whereKey("name", equalTo: filteredNameArray[indexPath.row])
                audioLocationName.text = filteredNameArray[indexPath.row]
            } else {
                query.whereKey("name", equalTo: nameArray[indexPath.row])
                audioLocationName.text = nameArray[indexPath.row]
            }
                query.findObjectsInBackground(block: { (objects, error) in
                    if error != nil {
                        print(error)
                    } else {
                        if let objects = objects {
                            tempPlayer = AVAudioPlayer()
                            for object in objects {
                                
                                if let audioClip = object["audio"] as? PFFile {
                                    audioClip.getDataInBackground(block: { (data, error) in
                                        if error != nil {
                                            print(error)
                                        } else {
                                            do { tempPlayer = try AVAudioPlayer(data: data!, fileTypeHint: AVFileTypeMPEGLayer3)
                                                self.trackPlaying = tempPlayer
                                                if tempPlayer != AVAudioPlayer() {
                                                    self.playNewSong()
                                                    if self.playButtonImage.isEnabled == false {
                                                        self.playButtonImage.isEnabled = true
                                                        self.scrubber.isEnabled = true
                                                        
                                                    } else {
                                                        self.trackPlaying.stop()
                                                    }
                                                }
                                                
                                            } catch {  print(error)
                                            }
                                        }
                                        self.activityIndicator.stopAnimating()
                                        UIApplication.shared.endIgnoringInteractionEvents()
                                    })
                                } else {
                                        // no audio found
                                    let audioPath = Bundle.main.path(forResource: "no audio", ofType: "mp3")
                                    do { let audioFiller = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath!))
                                        self.trackPlaying = audioFiller
                                        if tempPlayer != AVAudioPlayer() {
                                            self.playNewSong()
                                            if self.playButtonImage.isEnabled == false {
                                                self.playButtonImage.isEnabled = true
                                                self.scrubber.isEnabled = true
                                                
                                            } else {
                                                self.trackPlaying.stop()
                                            }

                                        }
                                    } catch {
                                        // error
                                    }
                                    self.activityIndicator.stopAnimating()
                                    UIApplication.shared.endIgnoringInteractionEvents()
                                }
                            }
                        }
                    }
                })
            

            
        } else {
            // no audio found
        }
    }
    
    func imageTapped(gesture: UIGestureRecognizer) {
        
        let overlay = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        let fullImageView = UIImageView(image: (gesture.view as! UIImageView).image) // This includes your image in table view cell
        fullImageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        fullImageView.contentMode = .scaleAspectFit
        
        let doneBtn = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)) // set up according to your requirements
        doneBtn.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        
        overlay.addSubview(fullImageView)
        overlay.addSubview(doneBtn)
        
        self.view.addSubview(overlay)
    }
    
    func pressed(sender: UIButton!) {
        
        sender.superview?.removeFromSuperview()
    }
    
    
    func playNewSong() {
            self.time = self.trackPlaying.duration
            self.trackPlaying.volume = 0.9
            self.trackPlaying.play()
            self.playButtonImage.setImage(UIImage(named: "pause.jpg"), for: .normal)
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateSlider), userInfo: nil, repeats: true)
            self.scrubber.maximumValue = Float(self.trackPlaying.duration)
            self.scrubber.value = 0
            self.playMode = true
        
            let minutes = Int(self.time / 60)
            var seconds = ""
            if Int(self.time) - (minutes * 60) < 10 {
                let tempSec = Int(self.time) - (minutes * 60)
                seconds = String("0\(tempSec)")
            } else {
                seconds = String(Int(self.time) - (minutes * 60))
            }

            self.audioTimeLeft.text = "\(minutes):\(seconds)"
    }
 
    func updateSlider() {
        scrubber.value = Float(trackPlaying.currentTime)
        
    }
    
    func decreaseTimer() {
        
        if time > 0 {
            time -= 1
            let minutes = Int(time/60)
            self.audioTimeLeft.text = "\(String(minutes)):\(String(Int((time) - Double(minutes*60))))"
            
        } else {
            timer.invalidate()
        }
    func timerOn() {
        updateSlider()
        decreaseTimer()
    }
        
}
    override func viewWillDisappear(_ animated: Bool) {
        
        if playMode {
            self.trackPlaying.stop()
        }
        
        nameArray.removeAll()
        coordinatesArray.removeAll()
        distanceArray.removeAll()
        addressArray.removeAll()
        completedArray.removeAll()
        imageDataArray.removeAll()
        sortingWithDistanceArray.removeAll()
        filteredNameArray.removeAll()
        
    }
    
}

extension POIsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
