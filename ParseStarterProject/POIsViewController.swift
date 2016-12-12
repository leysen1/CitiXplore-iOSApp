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

@available(iOS 10.0, *)
class POIsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    let moc = DataController().managedObjectContext

    var nameArray = [String]()
    var coreDataNameArray = [String]()
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

        coreDataFetch { (Bool) in
            newParseFetchAndSave { (Bool) in
                print("compelted")
            }
        }
        
    }


    override func viewDidAppear(_ animated: Bool) {
        
 
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchController.searchBar.endEditing(true)
        return true
    }


    func coreDataFetch(completion: (_ result: Bool)->()) {
        self.nameArray.removeAll()
        self.coreDataNameArray.removeAll()
        self.coordinatesArray.removeAll()
        self.distanceArray.removeAll()
        print("removed arrays")

        // Name and Coordinates
        // 1. get saved data
        let poiFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "POIs")
        
        do {
            let fetchedPOIs = try moc.fetch(poiFetch) as! [POIs]
            if fetchedPOIs.count > 0 {
                var i = 0
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
                    print("name array \(self.nameArray)")
                    i += 1
                    if i == fetchedPOIs.count {
                        completion(true)
                        print("completed")
                    }
                }
            } else {
                completion(true)
            }
        } catch {
            fatalError("Failed to fetch POI: \(error)")
        }
    }
    
    
    func newParseFetchAndSave(completion: (_ result: Bool)->()) {
        // 2. get new data from parse and (save to core data)
        print("Parse Query")
        let queryName = PFQuery(className: "POI")
        queryName.whereKey("area", equalTo: self.chosenAreaPOI)
        queryName.whereKey("name", notContainedIn: self.nameArray)
        queryName.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
                print("no objects found")
            } else {
                if let objects = objects {
                if objects.count > 0 {
                    print("objects found")
                    print(objects.count)

                    for object in objects {
                        let entity = NSEntityDescription.insertNewObject(forEntityName: "POIs", into: self.moc) as! POIs
                        print("object \(object["name"] as? String)")
                        // get the POI distances from user location
                        if let POILocation = object["coordinates"] as? PFGeoPoint {
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: POILocation.latitude, longitude: POILocation.longitude))
                            entity.setValue(POILocation.latitude, forKey: "latitude")
                            entity.setValue(POILocation.longitude, forKey: "longitude")
                            print(self.coordinatesArray)
                            if self.userLocation.latitude > 0 {
                                let tempUserLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                let tempPOILocation = CLLocation(latitude: POILocation.latitude, longitude: POILocation.longitude)
                                let distance = Double(tempUserLocation.distance(from: tempPOILocation) / 1000)
                                self.distanceArray.append(String(distance))
                                self.sortingWithDistanceArray.append(distance)

                            }
                            
                            if let nameTemp = object["name"] as? String {
                                self.nameArray.append(nameTemp)
                                entity.setValue(nameTemp, forKey: "name")
                            }
                        } else {
                            print("Could not get POI Location")
                        }
                        
                        do {
                            try self.moc.save()
                            print("saved")
                        } catch {
                            fatalError("Failure to save context: \(error)")
                        }

                    }
                }
                }
            }
        }
    }
    
    func distanceOrder(completion: (_ result: Bool)->()) {
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
            
        }
    }
    

    func coreDataFetch2(completion: (_ result: Bool)->()) {
        // Core Data address and completed
        let poiFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "POIs")
        for name in self.coreDataNameArray {
            poiFetch.predicate = NSPredicate(format: "name = %@", name)
            if let tempAddress = poiFetch.value(forKey: "address") {
                if let indexNumber = self.nameArray.index(of: name) {
                    if self.addressArray.count == self.nameArray.count {
                        self.addressArray[indexNumber] = (tempAddress as? String)!
                    }
                    if let tempCompleted = poiFetch.value(forKey: "completed") {
                        if self.completedArray.count == self.nameArray.count {
                            self.completedArray[indexNumber] = (tempCompleted as? String)!
                        }
                    }
                }
            }
        }
        
        
/*
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
        */
    }
    
    func ParseFetch2() {
        // Parse address, completed and images
        let queryRest = PFQuery(className: "POI")
        queryRest.whereKey("area", equalTo: self.chosenAreaPOI)
        queryRest.findObjectsInBackground { (objects, error) in
            if let objects = objects {
                
                for object in objects {
                    if let tempName = object["name"] as? String {
                        if let indexCheck = self.nameArray.index(of: tempName) {
                            // add photo to all POIs
                            if let photo = object["picture"] as? PFFile {
                                self.imageDataArray[indexCheck] = photo
                            }
                        
                            // add address and completed to only new POIs then Save to Core Data
                            if self.nameArray.contains(tempName) == false {
                                
                                let poiFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "POIs")
                                poiFetch.predicate = NSPredicate(format: "name = %@", tempName)
                                
                                if self.addressArray.count > 1 {
                                    if let tempAddress = object["address"] as? String {
                                        self.addressArray[self.nameArray.index(of: tempName)!] = tempAddress
                                        poiFetch.setValue(tempAddress, forKey: "address")
                                    }
                                }
                                if self.completedArray.count > 1 && self.username != nil {
                                    if let tempCompleted = object["completed"] as? [String] {
                                            if tempCompleted.contains(self.username!) {
                                                self.completedArray[self.nameArray.index(of: tempName)!] = "yes"
                                                poiFetch.setValue("yes", forKey: "completed")
                                            } else {
                                                poiFetch.setValue("no", forKey: "completed")
                                            }
                                        }
                                    }
                                    do {
                                        try self.moc.save()
                                    } catch { print("error") }
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
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // add in search count
        
        if completedArray.count > 0 || imageDataArray.count > 0 {
            if searchController.isActive && searchController.searchBar.text != "" {
                return filteredNameArray.count
            }

            return nameArray.count
        } else {
            return 0
        }
        
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

@available(iOS 10.0, *)
extension POIsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
