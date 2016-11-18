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
    var completedArray = [String]()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredNameArray = [String]()
    var chosenAreaPOI = ""
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredNameArray = nameArray.filter({ (skill) -> Bool in
            return skill.lowercased().contains(searchText.lowercased())
            
        })
        
        tableView.reloadData()
    }
    
    var imageDataArray = [PFFile]()
    
    var tappedPlaceForMap = String()
    
    @IBOutlet var tableView: UITableView!
    
    
    // audio Variables
    var audioArray = [AVAudioPlayer]()
    var trackPlaying = AVAudioPlayer()
    var playMode = false


 
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
        
        nameArray.removeAll()
        addressArray.removeAll()
        distanceArray.removeAll()
        coordinatesArray.removeAll()
        imageDataArray.removeAll()
        coordinatesArray.removeAll()
        audioArray.removeAll()
        
        // get POIs of the chosen area
        let query = PFQuery(className: "POI")
        query.whereKey("area", equalTo: chosenAreaPOI)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
                print("no objects found")
            } else {
                if let points = objects {
                    var testCompleted: [String]?
                    for point in points {
                        self.nameArray.append(point["name"] as! String)
                        self.addressArray.append(point["address"] as! String)
                        
                        testCompleted = (point["completed"] as? [String])
                        if testCompleted != nil {
                            if (testCompleted?.contains(self.username))! {
                                self.completedArray.append("yes")
                            } else {
                                self.completedArray.append("no")
                            }
                        } else {
                            self.completedArray.append("no")
                        }
                        // get POI audio
                        if let audioClip = point["audio"] as? PFFile {
                            audioClip.getDataInBackground(block: { (data, error) in
                                if error != nil {
                                    print(error)
                                    print("No audio found")
                                } else {
                                    var tempPlayer = AVAudioPlayer()
                                    do { tempPlayer = try AVAudioPlayer(data: data!, fileTypeHint: AVFileTypeMPEGLayer3)
                                        self.audioArray.append(tempPlayer)
                                    } catch {  print(error)
                                    }
                                }
                            })
                        } else {
                            // no audio found
                            let audioPath = Bundle.main.path(forResource: "Circle Of Life", ofType: "mp3")
                            do { let audioFiller = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath!))
                                self.audioArray.append(audioFiller)
                            } catch {
                                // error
                            }
                            
                        }
                        
                        // get the POI image
                        if let photo = point as? PFObject {
                            if photo["picture"] != nil {
                                self.imageDataArray.append(photo["picture"] as! PFFile)
                            } else {
                                // not images found
                                let photoFile = PFFile(data: UIImageJPEGRepresentation(UIImage(named: "cityview.jpg")!, 1.0)!)
                                self.imageDataArray.append(photoFile!)
                            }
                        }
                        
                        // get the POI coordinates
                        if let POILocation = point["coordinates"] as? PFGeoPoint {
                            let POICLLocation = CLLocation(latitude: POILocation.latitude, longitude: POILocation.longitude)
                            let userCLLocation = CLLocation(latitude: ((PFUser.current()?["location"] as? PFGeoPoint)?.latitude)!, longitude: ((PFUser.current()?["location"] as? PFGeoPoint)?.longitude)!)
                            let distance = userCLLocation.distance(from: POICLLocation) / 1000
                            let roundedDistance = round(distance * 100) / 100
                            self.distanceArray.append(String(roundedDistance))
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: POILocation.latitude, longitude: POILocation.longitude))
                            self.tableView.reloadData()
                        } else {
                            print("Could not get POI Location")
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: 0, longitude: 0))
                        }
                        
                    }
                    self.tableView.reloadData()
                    self.tableView.tableFooterView = UIView()
                    print("completed array \(self.completedArray)")
                    
                }
                
            }
        }
        

    }

    
    override func viewDidAppear(_ animated: Bool) {
        tappedPlaceForMap = ""
        
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
            
            if completedArray[indexValue!] == "yes" {
                
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
            
            cell.mapButton.tag = indexValue!
            cell.mapButton.addTarget(self, action: #selector(goToMap), for: .touchUpInside)
            
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
            
            cell.mapButton.tag = indexPath.row
            cell.mapButton.addTarget(self, action: #selector(goToMap), for: .touchUpInside)
        }

        

        
        // return
        return cell

    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if audioArray.count > 0 && nameArray.count > 0 {
            if self.playButtonImage.isEnabled == false {
                self.playButtonImage.isEnabled = true
                self.scrubber.isEnabled = true
                
            } else {
                trackPlaying.stop()
            }
            
            if searchController.isActive && searchController.searchBar.text != "" {
                let indexValue = nameArray.index(of: filteredNameArray[indexPath.row])
                trackPlaying = audioArray[indexValue!]
                audioLocationName.text = nameArray[indexValue!]
            } else {
                trackPlaying = audioArray[indexPath.row]
                audioLocationName.text = nameArray[indexPath.row]
            }
            
            time = trackPlaying.duration
            trackPlaying.volume = 0.9
            trackPlaying.play()
            playButtonImage.setImage(UIImage(named: "pause.jpg"), for: .normal)
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
            scrubber.maximumValue = Float(trackPlaying.duration)
            scrubber.value = 0
            playMode = true
            let minutes = Int(time/60)
            self.audioTimeLeft.text = "\(String(minutes)):\(String(Int((time) - Double(minutes*60))))"
            
        } else {
            // no audio found
        }
    }
    
    
    
    
    @IBAction func goToMap(sender: UIButton!) {
        if tappedPlaceForMap == "" && nameArray.count > 0 {
            tappedPlaceForMap = nameArray[sender.tag]
            print("tapped place \(tappedPlaceForMap)")
            performSegue(withIdentifier: "mapSegue", sender: self)
        } else {
            print("not ready to segue to map")
        }
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
    
    @IBAction func mapView(_ sender: AnyObject) {
        
        if playMode {
            self.trackPlaying.stop()
            performSegue(withIdentifier: "mapSegue", sender: self)
        } else {
            performSegue(withIdentifier: "mapSegue", sender: self)
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "mapSegue") {
            let MapVC = segue.destination as! MapViewController
            if tappedPlaceForMap != "" {
                MapVC.tappedPlaceForMapMV = tappedPlaceForMap
            } else {
                MapVC.tappedPlaceForMapMV = ""
            }
        }
    }
}

extension POIsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
