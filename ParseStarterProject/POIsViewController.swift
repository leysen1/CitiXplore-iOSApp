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

class POIsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    // circle of life video should be a "sorry there is no audio available at this time"
    
    let username = (PFUser.current()?.username!)!
    var nameArray = [String]()
    var addressArray = [String]()
    var distanceArray = [String]()
    var coordinatesArray = [CLLocationCoordinate2D]()
    var completedArray = [Int]()
    var completedArrayString = [String]()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredNameArray = [String]()
    var chosenAreaPOI = ""
    
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
    
    var imageDataArray = [PFFile]()
    
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

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        
        self.playButtonImage.isEnabled = false
        self.scrubber.isEnabled = false
        
        
        serialQueue.sync(execute: {
        // get POIs of the chosen area
        let query = PFQuery(className: "POI")
        query.whereKey("area", equalTo: chosenAreaPOI)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
                print("no objects found")
            } else {
                if let points = objects {
                    
                    self.nameArray.removeAll()
                    self.addressArray.removeAll()
                    self.distanceArray.removeAll()
                    self.coordinatesArray.removeAll()
                    self.imageDataArray.removeAll()
                    self.coordinatesArray.removeAll()
                    self.audioArray.removeAll()
                    
                    var testCompleted: [String]?

                    var distanceIntArray = [Double]()
                    var completedYesi = 1
                    var completedNoi = 1000
                    
                    for point in points {
                        
                        // get the POI coordinates
                        if let POILocation = point["coordinates"] as? PFGeoPoint {
                            let POICLLocation = CLLocation(latitude: POILocation.latitude, longitude: POILocation.longitude)
                            let userCLLocation = CLLocation(latitude: ((PFUser.current()?["location"] as? PFGeoPoint)?.latitude)!, longitude: ((PFUser.current()?["location"] as? PFGeoPoint)?.longitude)!)
                            let distance = userCLLocation.distance(from: POICLLocation) / 1000
                            let roundedDistance = round(distance * 100) / 100
                            distanceIntArray.append(Double(roundedDistance))
                            self.distanceArray.append(String(roundedDistance))
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: POILocation.latitude, longitude: POILocation.longitude))
                            self.tableView.reloadData()
                        } else {
                            print("Could not get POI Location")
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: 0, longitude: 0))
                        }
                        
                        self.nameArray.append(point["name"] as! String)
                        self.addressArray.append(point["address"] as! String)
  
                        // get the POI image
                        if let photo = point as? PFObject {
                            if photo["picture"] != nil {
                                self.imageDataArray.append(photo["picture"] as! PFFile)
                            } else {
                                // no images found
                                let photoFile = PFFile(data: UIImageJPEGRepresentation(UIImage(named: "cityview.jpg")!, 1.0)!)
                                self.imageDataArray.append(photoFile!)
                            }
                        }
                        
       
                        
                        testCompleted = (point["completed"] as? [String])
                        if testCompleted != nil {
                            if (testCompleted?.contains(self.username))! {
                                self.completedArray.append(completedYesi)
                                self.completedArrayString.append(String(completedYesi))
                                completedYesi += 1
                            } else {
                                self.completedArray.append(completedNoi)
                                self.completedArrayString.append(String(completedNoi))
                                completedNoi += 1
                            }
                        } else {
                            self.completedArray.append(completedNoi)
                            self.completedArrayString.append(String(completedNoi))
                            completedNoi += 1
                        }
                        
                        
                        
                    }
                    self.tableView.reloadData()
                    self.tableView.tableFooterView = UIView()
                    print("completed array \(self.completedArray)")
                    print("distanceIntArray \(distanceIntArray)")
                    
                    // combine into dict and sort
                    var dictName: [String: Double] = [:]
                    var dictAddress: [String: Double] = [:]
                    var dictDistance: [String: Double] = [:]
                    var dictCompleted: [String: Double] = [:]
                    
                    for (name, number) in self.nameArray.enumerated()
                    {
                        dictName[number] = distanceIntArray[name]
                    }
                    for (address, number) in self.addressArray.enumerated()
                    {
                        dictAddress[number] = distanceIntArray[address]
                    }
                    for (distance, number) in self.distanceArray.enumerated()
                    {
                        dictDistance[number] = distanceIntArray[distance]
                    }
                    for (completed, number) in self.completedArrayString.enumerated()
                    {
                        dictCompleted[number] = distanceIntArray[completed]
                    }
                    
                    let sortedName = (dictName as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
                    self.nameArray = sortedName as! [String]

                    
                    let sortedCompleted = (dictCompleted as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
                    self.completedArrayString = sortedCompleted as! [String]

                    
                    let sortedAddress = (dictAddress as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
                    self.addressArray = sortedAddress as! [String]

                    let sortedDistance = (dictDistance as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
                    self.distanceArray = sortedDistance as! [String]

                    
  
                    print("sortedKeys \(self.nameArray)")
                    print("sortedAddres \(self.addressArray)")
                    print("completed \(self.completedArray)")
                    print("distance \(self.distanceArray)")
                }
            }
        }    
        })
    }

    
    override func viewDidAppear(_ animated: Bool) {
        
        if nameArray.count < 1 {
            tableView.reloadData()
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
            
            if completedArray[indexValue!] < 1000 {
                
                cell.backgroundColor = UIColor.clear
                cell.locationName.textColor = UIColor.lightGray
                cell.locationAddress.textColor = UIColor.lightGray
                cell.locationDistance.textColor = UIColor.lightGray
                cell.locationImage.alpha = 0.5
                cell.tickImage.image = UIImage(named: "tick.png")
            } else {
                cell.backgroundColor = UIColor.groupTableViewBackground
                cell.locationName.textColor = UIColor.black
                cell.locationAddress.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
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

            if completedArray[indexPath.row] < 1000 {
                
                cell.backgroundColor = UIColor.clear
                cell.locationName.textColor = UIColor.lightGray
                cell.locationAddress.textColor = UIColor.lightGray
                cell.locationDistance.textColor = UIColor.lightGray
                cell.locationImage.alpha = 0.5
                cell.tickImage.image = UIImage(named: "tick.png")
            } else {
                cell.backgroundColor = UIColor.groupTableViewBackground
                cell.locationName.textColor = UIColor.black
                cell.locationAddress.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage()
            }
        }

        

        
        // return
        return cell

    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var tempPlayer = AVAudioPlayer()
        
        if nameArray.count > 0 {
            if self.playButtonImage.isEnabled == false {
                self.playButtonImage.isEnabled = true
                self.scrubber.isEnabled = true
                
            } else {
                trackPlaying.stop()
            }
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
                                                }
                                                
                                            } catch {  print(error)
                                            }
                                        }
                                    })
                                } else {
                                        // no audio found
                                    let audioPath = Bundle.main.path(forResource: "Circle Of Life", ofType: "mp3")
                                    do { let audioFiller = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath!))
                                        self.trackPlaying = audioFiller
                                        if tempPlayer != AVAudioPlayer() {
                                            self.playNewSong()
                                        }
                                    } catch {
                                        // error
                                    }
                                    
                                }
                            }
                        }
                    }
                })

            
        } else {
            // no audio found
        }
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
            let minutes = Int(self.time/60)
            self.audioTimeLeft.text = "\(String(minutes)):\(String(Int((self.time) - Double(minutes*60))))"
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
        
    }
    
}

extension POIsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
