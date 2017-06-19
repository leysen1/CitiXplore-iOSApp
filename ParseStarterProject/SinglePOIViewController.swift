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
    var area = String()
    var category = String()
    var address = String()
    var distance = String()
    var coordinates = CLLocationCoordinate2D()
    var completed = String()
    var imageData = [PFFile]()
    var poiDescription = String()
    var rating = Int()
    var delegate: MapClickedDelegate? = nil

    var trackPlaying = AVAudioPlayer()
    var trackPlaying2 = AVAudioPlayer()
    var playMode = false
    var playMode2 = false
    var timer = Timer()
    var timer2 = Timer()
    var time = Double()
    var time2 = Double()
    var audio2Exists = false
    var poiCoord = CLLocationCoordinate2D()
    var activityIndicator = UIActivityIndicatorView()
    
    @IBOutlet weak var navBarBox: UINavigationBar!
    
    // top section
    @IBOutlet var backgroundLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var areaAndCategoryLabel: UILabel!
    @IBOutlet weak var poiDistance: UILabel!
    @IBOutlet weak var poiAddress: UILabel!
    @IBOutlet weak var completedImage: UIImageView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var starImage: UIImageView!
    
    // lower section
    @IBOutlet weak var poiImage: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet var openingTimesLabel: UILabel!
    @IBOutlet var websiteLink: UILabel!
    @IBOutlet weak var checkOffLabel: UIButton!

    
    // first audio
    @IBOutlet var historyLabel: UILabel!
    @IBOutlet var scrubber: UISlider!
    @IBOutlet var audioTimeLeft: UILabel!
    @IBOutlet var playButtonImage: UIButton!
    
    // second audio
    @IBOutlet var scrubber2: UISlider!
    @IBOutlet var playButtonImage2: UIButton!
    @IBOutlet var audioLabel2: UILabel!
    @IBOutlet var audioTimeLeft2: UILabel!
    
    
    // Buttons 
    
    @IBAction func segueToMap(_ sender: Any) {
        print("map pressed")
        ratedPOI = name
        if delegate != nil {
            delegate?.mapClicked(data: true)
            self.dismiss(animated: true, completion: nil)
        }

    }
    
    @IBAction func checkOffButton(_ sender: Any) {
        
        if checkOffLabel.title(for: .normal) == "Seen it already?" {
            print("seen already")
            createAlert(title: "Look at you!", message: "Are you sure you want to check off this POI?")
        } else {
            print("not seen")
            createAlert(title: "Changed you mind?", message: "Are you sure you want to uncheck this POI?")
        }
    }
    
    @IBAction func scrubberChanged(_ sender: AnyObject) {
        trackPlaying.currentTime = TimeInterval(scrubber.value)
    }

    @IBAction func scrubber2Changed(_ sender: Any) {
        trackPlaying2.currentTime = TimeInterval(scrubber2.value)
    }
    
    @IBAction func playPauseButton(_ sender: AnyObject) {
        
        if playMode == true {
            // pausing audio
            playButtonImage.setImage(UIImage(named: "play.png"), for: .normal)
            trackPlaying.pause()
            timer.invalidate()
            playMode = false
        } else {
            // playing audio
            if audio2Exists {
                playButtonImage2.setImage(UIImage(named: "play.png"), for: .normal)
                trackPlaying2.pause()
                timer2.invalidate()
                playMode2 = false
            }
            playButtonImage.setImage(UIImage(named: "pause.png"), for: .normal)
            trackPlaying.play()
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
            playMode = true
        }
    }
    
    @IBAction func playPauseButton2(_ sender: Any) {
        if playMode2 == true {
            // pausing audio
            playButtonImage2.setImage(UIImage(named: "play.png"), for: .normal)
            trackPlaying2.pause()
            timer2.invalidate()
            playMode2 = false
        } else {
            // playing audio
            playButtonImage.setImage(UIImage(named: "play.png"), for: .normal)
            trackPlaying.pause()
            timer.invalidate()
            playMode = false
            
            playButtonImage2.setImage(UIImage(named: "pause.png"), for: .normal)
            trackPlaying2.play()
            timer2 = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSlider2), userInfo: nil, repeats: true)
            playMode2 = true
        }
    }
    
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true) {
            print("dismissed")  }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        // Aesthetics
        
        playButtonImage.isEnabled = false
        scrubber.isEnabled = false
        checkOffLabel.layer.cornerRadius = 5
        checkOffLabel.layer.masksToBounds = true
        navigationController?.setToolbarHidden(true, animated: true)
        poiImage.layer.cornerRadius = 10
        poiImage.layer.masksToBounds = true
        mapView.layer.cornerRadius = 10
        mapView.layer.masksToBounds = true
        descriptionLabel.layer.cornerRadius = 10
        descriptionLabel.layer.masksToBounds = true
        descriptionLabel.font = UIFont(name: "Avenir Next", size: 13)
        historyLabel.text = "Loading..."
        
        scrubber2.alpha = 0
        audioTimeLeft2.alpha = 0
        playButtonImage2.alpha = 0
        audioLabel2.alpha = 0
        playButtonImage2.isEnabled = false
        
        // Functions
        
        fetchData { (Bool) in
            self.populateLabels()
        }
        
        fetchAudio { (Bool) in
            self.prepareAudio()
        }
        
        loadMap { (Bool) in
            let region = MKCoordinateRegion(center: self.poiCoord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: false)
            self.addAnnotationToMap()

        }


    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Aesthetics 
        
        self.view.backgroundColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        checkOffLabel.backgroundColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        
        titleLabel.text = name
        titleLabel.adjustsFontSizeToFitWidth = true
        
        navBarBox.barTintColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        navBarBox.shadowImage = UIImage()
        navBarBox.setBackgroundImage(UIImage(), for: .default)
        backgroundLabel.backgroundColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if playMode {
            self.trackPlaying.stop()
        }
        if playMode2 {
            self.trackPlaying2.stop() }
        name = ""
        coordinates = CLLocationCoordinate2D()
        distance = ""
        address = ""
        completed = ""
        imageData.removeAll()
    }
    
    // Functions
    
    func updateSlider() {
        
        scrubber.value = Float(trackPlaying.currentTime)
        if scrubber.value == 0 {
            // pausing audio
            playButtonImage.setImage(UIImage(named: "play.png"), for: .normal)
            trackPlaying.pause()
            timer.invalidate()
            playMode = false
        }
    }
    
    func updateSlider2() {
        
        scrubber2.value = Float(trackPlaying2.currentTime)
        if scrubber2.value == 0 {
            // pausing audio
            playButtonImage2.setImage(UIImage(named: "play.png"), for: .normal)
            trackPlaying2.pause()
            timer2.invalidate()
            playMode2 = false
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
    func decreaseTimer2() {
        
        if time2 > 0 {
            time2 -= 1
            let minutes2 = Int(time2/60)
            self.audioTimeLeft2.text = "\(String(minutes2)):\(String(Int((time2) - Double(minutes2*60))))"
        } else {
            timer2.invalidate()
        }
        func timerOn() {
            updateSlider2()
            decreaseTimer2()
        }
        
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
                        if let tempArea = object["area"] as? String {
                            self.area = tempArea
                        }
                        if let tempCategory = object["Category"] as? String {
                            self.category = tempCategory
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
                                self.ratingLabel.text = "Point of Interest"
                            case 2:
                                self.ratingLabel.text = "Worth a detour"
                            case 3:
                                self.ratingLabel.text = "Worth a visit when in the area"
                            case 4:
                                self.ratingLabel.text = "Must See"
                            default:
                                break
                            }
                           
                        }
                        if let tempDescription = object["description"] as? String {
                            self.poiDescription = tempDescription
                        } else { self.poiDescription = "Description Coming Soon."   }
                        if let tempAudio2Name = object["audio2Name"] as? String {
                            self.audioLabel2.text = tempAudio2Name
                        }
                        if let tempWebsite = object["websiteLink"] as? String {
                            self.websiteLink.text = tempWebsite
                        }
                        if let tempOpeningTimes = object["openingTimes"] as? String {
                            self.openingTimesLabel.text = tempOpeningTimes
                        }
   
                        i += 1
                        if i == objects.count { completion(true)    }
                    }
                } else { completion(true)   }
            }
        }
    }
    
    func populateLabels() {
        
        print("data fetched")
        print("completed \(self.completed)")
        self.poiAddress.text = self.address
        self.poiDistance.text = "\(self.distance) km"
        self.descriptionLabel.text = self.poiDescription
        self.areaAndCategoryLabel.text = "\(self.area), \(self.category)"
        
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
            self.completedImage.layer.masksToBounds = true
            self.completedImage.layer.cornerRadius = 5
            self.checkOffLabel.setTitle("Not yet seen?", for: .normal)
        } else {
            self.completedImage.image = UIImage()
            self.checkOffLabel.setTitle("Seen it already?", for: .normal)
        }
        
        // stars
        switch self.rating {
        case 1:
            self.starImage.image = UIImage(named: "star.png")
            self.starImage.frame = CGRect(x: 15, y: 62, width: 20, height: 20)
        case 2:
            self.starImage.image = UIImage(named: "2star.png")
            self.starImage.frame = CGRect(x: 15, y: 62, width: 40, height: 20)
        case 3:
            self.starImage.image = UIImage(named: "3star.png")
            self.starImage.frame = CGRect(x: 15, y: 62, width: 60, height: 20)
        case 4:
            self.starImage.image = UIImage(named: "4star.png")
            self.starImage.frame = CGRect(x: 15, y: 62, width: 80, height: 20)
        default:
            break
        }
        
    }
    
    func fetchAudio(completion: @escaping (_ result: Bool)->()) {
        var tempPlayer = AVAudioPlayer()
        var tempPlayer2 = AVAudioPlayer()
        let query = PFQuery(className: "POI")
        query.whereKey("name", equalTo: name)
        query.findObjectsInBackground(block: { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        if let audioClip = object["audio"] as? PFFile {
                            audioClip.getDataInBackground(block: { (data, error) in
                                if error != nil {
                                    print("error")
                                } else {
                                    do { tempPlayer = try AVAudioPlayer(data: data!, fileTypeHint: AVFileTypeMPEGLayer3)
                                        self.trackPlaying = tempPlayer
                                        i += 1
                                        if i == 2 {
                                            completion(true)
                                        }
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
                                    } catch {  print(error)
                                    }

                                }
                            })
                        } else {
                            // no audio found
                            let audioPath = Bundle.main.path(forResource: "no audio", ofType: "mp3")
                            do { let audioFiller = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath!))
                                self.trackPlaying = audioFiller
                                i += 1
                                if i == 2 {
                                    completion(true)
                                }
                            } catch {
                                // error
                            }

                        }
                        // second audio
                        if let audioClip = object["audio2"] as? PFFile {
                            audioClip.getDataInBackground(block: { (data, error) in
                                if error != nil {
                                    print("error")
                                } else {
                                    do { tempPlayer2 = try AVAudioPlayer(data: data!, fileTypeHint: AVFileTypeMPEGLayer3)
                                        self.trackPlaying2 = tempPlayer2
                                        self.audio2Exists = true
                                        i += 1
                                        if i == 2 {
                                            completion(true)
                                        }
                                        // background playing
                                    } catch {  print(error)
                                    }
                                }
                            })
  
                        } else {
                            i += 1
                            if i == 2 {
                                completion(true)
                            }
                        }
                    }
                }
            }
        })
    }

    func prepareAudio() {
        
        // first audio
        self.trackPlaying.volume = 0.9
        self.time = self.trackPlaying.duration / 1.37
        self.playButtonImage.setImage(UIImage(named: "play.png"), for: .normal)
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
        
        self.playButtonImage.isEnabled = true
        self.historyLabel.text = "History"
        self.scrubber.isEnabled = true
        
        self.audioTimeLeft.text = "\(minutes):\(seconds)"
        
        // second audio
        if self.audio2Exists == true {
            self.trackPlaying2.volume = 0.9
            self.time2 = self.trackPlaying2.duration / 1.37
            self.playButtonImage2.setImage(UIImage(named: "play.png"), for: .normal)
            self.timer2 = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateSlider2), userInfo: nil, repeats: true)
            self.scrubber2.maximumValue = Float(self.trackPlaying2.duration / 1.37)
            self.scrubber2.value = 0
            self.playMode2 = false
            
            let minutes2 = Int(self.time2 / 60)
            var seconds2 = ""
            if Int(self.time2) - (minutes2 * 60) < 10 {
                let tempSec2 = Int(self.time2) - (minutes2 * 60)
                seconds2 = String("0\(tempSec2)")
            } else {
                seconds2 = String(Int(self.time2) - (minutes2 * 60))
            }
            
            self.audioTimeLeft2.text = "\(minutes2):\(seconds2)"
            scrubber2.alpha = 1
            audioTimeLeft2.alpha = 1
            playButtonImage2.alpha = 1
            audioLabel2.alpha = 1
            playButtonImage2.isEnabled = true
            
        }
        
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
}
