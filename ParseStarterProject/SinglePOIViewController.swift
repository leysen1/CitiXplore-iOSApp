//
//  SinglePOIViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 21/11/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import AVFoundation

class SinglePOIViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    var name = String()

    var address = String()
    var distance = String()
    var coordinates = CLLocationCoordinate2D()
    var completed = String()
    var imageData = [PFFile]()

    var audio = AVAudioPlayer()
    var trackPlaying = AVAudioPlayer()
    var playMode = false
    var timer = Timer()
    var time = Double()
    
    var activityIndicator = UIActivityIndicatorView()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var scrubber: UISlider!
    @IBAction func scrubberChanged(_ sender: AnyObject) {
        trackPlaying.currentTime = TimeInterval(scrubber.value)
    }
    @IBOutlet var audioLocationName: UILabel!
    @IBOutlet var audioTimeLeft: UILabel!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Listen"
        self.playButtonImage.isEnabled = false
        self.scrubber.isEnabled = false
        
        let query = PFQuery(className: "POI")
        query.whereKey("name", equalTo: name)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
            } else {
                if let objects = objects {
                    for object in objects {
                        if let tempaddress = object["address"] as? String {
                            self.address = tempaddress
                        } else {
                            self.address = "none found"
                        }
                        if let tempPOILocation = object["coordinates"] as? PFGeoPoint {
                            
                            let POILocation = CLLocation(latitude: tempPOILocation.latitude, longitude: tempPOILocation.longitude)
                            
                            if let userLocTemp = PFUser.current()?["location"] as? PFGeoPoint {
                                
                                let userLocation = CLLocation(latitude: userLocTemp.latitude, longitude: userLocTemp.longitude)
                                
                                let tempDistance = Double(userLocation.distance(from: POILocation) / 1000)
                                let roundedDistance = round(tempDistance * 100) / 100
                                
                                self.distance = String(roundedDistance)
                                
                                self.coordinates = CLLocationCoordinate2D(latitude: POILocation.coordinate.latitude, longitude: POILocation.coordinate.longitude)
                            }
                        } else {
                            self.distance = "N/A"
                        }
                        
                        if let tempCompletedArray = object["completed"] as? [String] {
                            if let username = (PFUser.current()?.username!) {
                                if tempCompletedArray.contains(username) {
                                    self.completed = "yes"
                                } else {
                                    self.completed = "no"
                                }
                            }
                        } else {
                            self.completed = "no"
                        }
                        
                        if let tempPhoto = object["picture"] as? PFFile {
                            self.imageData.append(tempPhoto)
                        } else {
                            if let imageFiller = UIImage(named: "NA.png") {
                                if let imageFillerData = UIImageJPEGRepresentation(imageFiller, 1.0) {
                                    self.imageData.append(PFFile(data: imageFillerData)!)
                                }
                            }
                        }
                        self.tableView.reloadData()
                        self.tableView.tableFooterView = UIView()
                    }
                    self.tableView.reloadData()
                }
            }
    }

}
    

    
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SinglePOITableViewCell
        cell.locationName.text = name
        cell.locationAddress.text = address
        if distance != "" {
            cell.locationDistance.text = "You are \(distance)km away"
        }
        
        if imageData != [] {
            imageData[0].getDataInBackground { (data, error) in
                
                if let tempImageData = data {
                    if let downloadedImage = UIImage(data: tempImageData) {
                        cell.locationImage.image = downloadedImage
                    }
                }
            }
        }
        
        if completed == "yes" {
            
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        cell.locationImage.addGestureRecognizer(tapGesture)
        cell.locationImage.isUserInteractionEnabled = true

         return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var tempPlayer = AVAudioPlayer()
        
        if name != "" {
            //Spinner
            activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            activityIndicator.startAnimating()
            UIApplication.shared.beginIgnoringInteractionEvents()
            view.addSubview(activityIndicator)
            
            audioLocationName.text = name
            let query = PFQuery(className: "POI")
            query.whereKey("name", equalTo: name)
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
            if self.playButtonImage.isEnabled == false {
                self.playButtonImage.isEnabled = true
                self.scrubber.isEnabled = true
            } else {
                trackPlaying.stop()
            }
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
    

    

    override func viewWillDisappear(_ animated: Bool) {
        
        if playMode {
            self.trackPlaying.stop()
        }
        
        name = ""
        coordinates = CLLocationCoordinate2D()
        distance = ""
        address = ""
        completed = ""
        imageData.removeAll()
        
    }
    

}
