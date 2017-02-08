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

protocol MapClickedDelegate {
    func mapClicked(data: Bool)
}


class SinglePOIViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var name = String()
    var address = String()
    var distance = String()
    var coordinates = CLLocationCoordinate2D()
    var completed = String()
    var imageData = [PFFile]()
    var poiDescription = String()
    var rating = Int()
    var delegate: MapClickedDelegate? = nil

    var audio = AVAudioPlayer()
    var trackPlaying = AVAudioPlayer()
    var playMode = false
    var timer = Timer()
    var time = Double()
    var poiCoord = CLLocationCoordinate2D()
    
    @IBOutlet weak var navBarBox: UINavigationBar!
    @IBOutlet weak var checkOffLabel: UIButton!
    @IBAction func checkOffButton(_ sender: Any) {
        
        if checkOffLabel.title(for: .normal) == "Seen it already?" {
            print("seen already")
            createAlert(title: "Look at you!", message: "Are you sure you want to check off this POI?")
        } else {
            print("not seen")
            createAlert(title: "Changed you mind?", message: "Are you sure you want to uncheck this POI?")
        }
        
    }
    @IBOutlet weak var nameBackground: UILabel!
    @IBOutlet weak var starImage: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBAction func segueToMap(_ sender: Any) {
        
        print("map pressed")
        ratedPOI = name
        if delegate != nil {
            delegate?.mapClicked(data: true)
            self.dismiss(animated: true, completion: nil)
        }

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
        if scrubber.value == 0 {
            // pausing audio
            playButtonImage.setImage(UIImage(named: "play.jpg"), for: .normal)
            trackPlaying.pause()
            timer.invalidate()
            playMode = false
        }
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
        
        print("hello")
        print(name)
        playButtonImage.isEnabled = false
        scrubber.isEnabled = false
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        checkOffLabel.layer.cornerRadius = 5
        checkOffLabel.layer.masksToBounds = true
        navigationController?.setToolbarHidden(true, animated: true)
        poiImage.layer.cornerRadius = 10
        poiImage.layer.masksToBounds = true
        mapView.layer.cornerRadius = 10
        mapView.layer.masksToBounds = true
        descriptionLabel.layer.cornerRadius = 10
        descriptionLabel.layer.masksToBounds = true
        
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
                self.checkOffLabel.setTitle("Not yet seen?", for: .normal)
            } else {
                self.completedImage.image = UIImage()
                self.checkOffLabel.setTitle("Seen it already?", for: .normal)
            }
            
            // stars
            switch self.rating {
            case 1:
                self.starImage.image = UIImage(named: "star.png")
                self.starImage.frame = CGRect(x: 15, y: 65, width: 20, height: 20)
            case 2:
                self.starImage.image = UIImage(named: "2star.png")
                self.starImage.frame = CGRect(x: 15, y: 65, width: 40, height: 20)
            case 3:
                self.starImage.image = UIImage(named: "3star.png")
                self.starImage.frame = CGRect(x: 15, y: 65, width: 60, height: 20)
            case 4:
                self.starImage.image = UIImage(named: "4star.png")
                self.starImage.frame = CGRect(x: 15, y: 65, width: 80, height: 20)
            default:
                break
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
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.view.backgroundColor = UIColor(red: 0/255,  green: 128/255, blue: 128/255, alpha: 1.0)
        nameBackground.backgroundColor = UIColor(red: 0/255,  green: 128/255, blue: 128/255, alpha: 1.0)
        checkOffLabel.backgroundColor = UIColor(red: 0/255,  green: 128/255, blue: 128/255, alpha: 1.0)
        navBarBox.barTintColor = UIColor(red: 0/255,  green: 128/255, blue: 128/255, alpha: 1.0)
        navBarBox.titleTextAttributes = [NSFontAttributeName : UIFont(name: "AvenirNext-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20), NSForegroundColorAttributeName: UIColor.white]
        navBarBox.shadowImage = UIImage()
        navBarBox.setBackgroundImage(UIImage(), for: .default)
        
        //self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        //self.navigationController?.navigationBar.shadowImage = UIImage()
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Annotate {
            let identifier = "pin"
            var view: MKAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                dequeuedView.annotation = annotation
                view = dequeuedView
                
                
            } else {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                view.image = UIImage(named: "Cross")
                
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure) as UIView
                
            }
            return view
        }
        return nil
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
                            self.rating = tempRating
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
                                        // background playing
                                        do {
                                            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                                            print("AVAudioSession Category Playback OK")
                                            do {
                                                try AVAudioSession.sharedInstance().setActive(true)
                                                print("AVAudioSession is Active")
                                            } catch let error as NSError {
                                                print(error.localizedDescription)
                                            }
                                        } catch let error as NSError {
                                            print(error.localizedDescription)
                                        }
                                        
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
        self.time = self.trackPlaying.duration / 1.37
        self.trackPlaying.volume = 0.9
        self.playButtonImage.setImage(UIImage(named: "play.jpg"), for: .normal)
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateSlider), userInfo: nil, repeats: true)
        self.scrubber.maximumValue = Float(self.trackPlaying.duration / 1.37)
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
        
        let annotate = Annotate(title: name, locationName: address, coordinate: poiCoord, imagePOI: UIImage(named: "Cross")!)
        mapView.addAnnotation(annotate)
        mapView.reloadInputViews()
    }

    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.updateRecentPOIs()
            if self.checkOffLabel.title(for: .normal) == "Seen it already?" {
                // checking POI
                self.checkOffLabel.setTitle("Not yet seen?", for: .normal)
                
                let query = PFQuery(className: "POI")
                query.whereKey("name", equalTo: self.name)
                query.findObjectsInBackground(block: { (objects, error) in
                    if error != nil {
                        print("error")
                    } else {
                        if let objects = objects {
                            for object in objects {
                                if let email = PFUser.current()?.username {
                                    object.addUniqueObject(email, forKey: "completed")
                                    object.addUniqueObject(email, forKey: "completedRemote")
                                    object.saveInBackground()
                                    print("Added POI and saved")
                                }
                                
                            }
                        }
                    }
                })
                
            } else {
                // unchecking POI
                self.checkOffLabel.setTitle("Seen it already?", for: .normal)
                let query = PFQuery(className: "POI")
                query.whereKey("name", equalTo: self.name)
                query.findObjectsInBackground(block: { (objects, error) in
                    if error != nil {
                        print("error")
                    } else {
                        if let objects = objects {
                            for object in objects {
                                if let email = PFUser.current()?.username {
                                    if let tempCompleted = object["completed"] as? [String] {
                                        if tempCompleted.contains(email) {
                                            object.remove(email, forKey: "completed")
                                            object.remove(email, forKey: "completedRemote")
                                            object.saveInBackground()
                                            print("removed completed POI and saved")
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                })
            }
        }))
        
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func updateRecentPOIs() {
        if self.checkOffLabel.title(for: .normal) == "Seen it already?" {
            // check POI
            let query = PFQuery(className: "_User")
            query.whereKey("username", equalTo: (PFUser.current()?.username!)!)
            query.findObjectsInBackground { (objects, error) in
                if error != nil {
                    print("error")
                } else {
                    if let objects = objects {
                        for object in objects {
                            object.addUniqueObject(self.name, forKey: "completed")
                            object.saveInBackground()
                            print("recent POI saved")
                        }
                    }
                }
            }
        } else {
            // uncheck POI
            let query = PFQuery(className: "_User")
            query.whereKey("username", equalTo: (PFUser.current()?.username!)!)
            query.findObjectsInBackground { (objects, error) in
                if error != nil {
                    print("error")
                } else {
                    if let objects = objects {
                        for object in objects {
                            object.remove(self.name, forKey: "completed")
                            object.saveInBackground()
                            print("removed POI")
                        }
                    }
                }
            }
            
        }
        
        
        
    }
    
    @IBAction func back(_ sender: Any) {
        
        self.dismiss(animated: true) {
            print("dismissed")
        }
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
