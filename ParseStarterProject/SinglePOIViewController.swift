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
import MapKit

class SinglePOIViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var name = String()
    var address = String()
    var distance = String()
    var coordinates = CLLocationCoordinate2D()
    var completed = String()
    var imageData = [PFFile]()
    var poiDescription = String()

    var audio = AVAudioPlayer()
    var trackPlaying = AVAudioPlayer()
    var playMode = false
    var timer = Timer()
    var time = Double()
    var poiCoord = CLLocationCoordinate2D()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBAction func segueToMap(_ sender: Any) {
        
        print("map pressed")
        ratedPOI = name
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBOutlet weak var descriptionLabel: UITextView!
    
    var activityIndicator = UIActivityIndicatorView()
    
    @IBOutlet weak var poiName: UILabel!
    @IBOutlet weak var poiDistance: UILabel!
    @IBOutlet weak var poiImage: UIImageView!
    @IBOutlet weak var poiAddress: UILabel!
    @IBOutlet weak var completedImage: UIImageView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet var scrubber: UISlider!
    @IBAction func scrubberChanged(_ sender: AnyObject) {
        trackPlaying.currentTime = TimeInterval(scrubber.value)
    }
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
        
        title = "Listen"
        navigationController?.navigationBar.barTintColor = UIColor.white

        print("hello")
        print(name)
        playButtonImage.isEnabled = false
        scrubber.isEnabled = false
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        fetchData { (Bool) in
            print("data fetched")
            print("completed \(self.completed)")
            self.poiName.text = self.name
            self.poiAddress.text = self.address
            self.poiDistance.text = "\(self.distance) km"
            self.descriptionLabel.text = self.poiDescription
            
            if self.imageData != [] {
                self.imageData[0].getDataInBackground { (data, error) in
                    if let tempImageData = data {
                        if let downloadedImage = UIImage(data: tempImageData) {
                            self.poiImage.image = downloadedImage
                        }
                    }
                }
            }
            if self.completed == "yes" {
                self.completedImage.image = UIImage(named: "tick.png")
            } else {
                self.completedImage.image = UIImage()
            }
            
        }
        
        fetchAudio { (Bool) in
            self.playButtonImage.isEnabled = true
            self.scrubber.isEnabled = true
            self.prepareAudio()
        }
        
        loadMap { (Bool) in
            let region = MKCoordinateRegion(center: self.poiCoord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: false)
            self.addAnnotationToMap()

        }


    }
    
    func fetchData(completion: @escaping (_ result: Bool)->()) {
        let query = PFQuery(className: "POI")
        query.whereKey("name", equalTo: name)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
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
                            if let email = (PFUser.current()?.username!) {
                                if tempCompletedArray.contains(email) {
                                    self.completed = "yes"
                                } else {
                                    self.completed = "no"
                                }
                            }
                        } else {
                            self.completed = "no"
                        }
                        
                        if let tempPhoto = object["smallPicture"] as? PFFile {
                            self.imageData.append(tempPhoto)
                        } else {
                            if let imageFiller = UIImage(named: "NA.png") {
                                if let imageFillerData = UIImageJPEGRepresentation(imageFiller, 1.0) {
                                    self.imageData.append(PFFile(data: imageFillerData)!)
                                }
                            }
                        }
                        if let tempRating = object["ratings"] as? Int {
                            switch tempRating {
                            case 1:
                                self.ratingLabel.text = "Interesting POI"
                            case 2:
                                self.ratingLabel.text = "Worth a detour"
                            case 3:
                                self.ratingLabel.text = "Worth a visit when in the area"
                            case 4:
                                self.ratingLabel.text = "Worth a visit when in the city"
                            default:
                                break
                            }
                           
                        } else {
                            
                        }
                        
                        if let tempDescription = object["description"] as? String {
                            self.poiDescription = tempDescription
                        } else {
                            self.poiDescription = "Description Coming Soon."
                        }
                        
                        i += 1
                        if i == objects.count {
                            completion(true)
                        }
                    }

                } else {
                    completion(true)
                }
            }
        }
    }
    
    func fetchAudio(completion: @escaping (_ result: Bool)->()) {
        var tempPlayer = AVAudioPlayer()
        let query = PFQuery(className: "POI")
        query.whereKey("name", equalTo: name)
        query.findObjectsInBackground(block: { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    tempPlayer = AVAudioPlayer()
                    for object in objects {
                        if let audioClip = object["audio"] as? PFFile {
                            audioClip.getDataInBackground(block: { (data, error) in
                                if error != nil {
                                    print("error")
                                } else {
                                    do { tempPlayer = try AVAudioPlayer(data: data!, fileTypeHint: AVFileTypeMPEGLayer3)
                                        self.trackPlaying = tempPlayer
                                        completion(true)
                                    } catch {  print(error)
                                    }
                                }
                            })
                        } else {
                            // no audio found
                            let audioPath = Bundle.main.path(forResource: "no audio", ofType: "mp3")
                            do { let audioFiller = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath!))
                                self.trackPlaying = audioFiller
                                completion(true)
                            } catch {
                                // error
                            }
                        }
                    }
                } else {
                    completion(true)
                }
            }
        })
    }

    func prepareAudio() {
        self.time = self.trackPlaying.duration
        self.trackPlaying.volume = 0.9
        self.playButtonImage.setImage(UIImage(named: "play.jpg"), for: .normal)
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateSlider), userInfo: nil, repeats: true)
        self.scrubber.maximumValue = Float(self.trackPlaying.duration)
        self.scrubber.value = 0
        self.playMode = false
        
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
    
    func loadMap(completion: @escaping (_ result: Bool)->()) {
        
        let query = PFQuery(className: "POI")
        query.whereKey("name", equalTo: name)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    for object in objects {
                        if let tempLocation = object["coordinates"] as? PFGeoPoint {
                            self.poiCoord = CLLocationCoordinate2D(latitude: tempLocation.latitude, longitude: tempLocation.longitude)
                            completion(true)
                        }

                    }
                }
            }
        }
    }
    

    
    func addAnnotationToMap() {
        
        let annotate = Annotate(title: name, locationName: address, coordinate: poiCoord, color: MKPinAnnotationColor.red)
        mapView.addAnnotation(annotate)
        mapView.reloadInputViews()
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
