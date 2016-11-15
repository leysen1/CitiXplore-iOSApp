//
//  MapViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 12/10/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit
import AVKit
import AVFoundation


// learn how to color annotation
// add coloured annotation points for those not completed. ie with MKPointAnnotation
// add to completed when nearby


class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 51.4881398, longitude: -0.1866036)
    var annotationArray: [MKPointAnnotation] = []
    var userAnnotation = MKPointAnnotation()
    
    /*
    var audioPlayer = AVAudioPlayer()
    var audioArray = [Data]()
    var timer = Timer()
    var audioDuration = TimeInterval()
    var playerArray = [AVAudioPlayer]()
    */
    
    @IBOutlet var mapView: MKMapView!

    @IBAction func areaView(_ sender: AnyObject) {
        navigationController?.dismiss(animated: true, completion: {
            
        })
    }
        override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
            
        
            
        // save user location
        PFUser.current()?["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
        PFUser.current()?.saveInBackground(block: { (success, error) in
            if error != nil {
                print(error)
            } else {
                print("saved user location")
            }
        })
          
            // find all POIs
            let query = PFQuery(className: "POI")
            query.findObjectsInBackground(block: { (objects, error) in
                if let poiLocations = objects {
                    for poiLocation in poiLocations {
                        let POIAnnotation = MKPointAnnotation()
                        POIAnnotation.coordinate = CLLocationCoordinate2D(latitude: (poiLocation["coordinates"] as AnyObject).latitude, longitude: (poiLocation["coordinates"] as AnyObject).longitude)
                        POIAnnotation.title = poiLocation["name"] as? String
                        POIAnnotation.subtitle = poiLocation["address"] as? String
                        self.annotationArray.append(POIAnnotation)
                 
                    }
                    print("please see annotations below")
                    print(self.annotationArray)
                }
            })
    
            
        // findAudio()
            
        // set map view
        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
        self.mapView.setRegion(region, animated: false)
            
        // annotation
        let annotate = Annotate(title: "King David Kalakaua", locationName: "Waikiki Gateway Park", discipline: "Sculpture", coordinate: CLLocationCoordinate2D(latitude: 51.4881398, longitude: -0.1866036))
        mapView.addAnnotation(annotate)

            
        mapView.delegate = self
            
    }
  
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationCoord = manager.location?.coordinate {
            
            userLocation = CLLocationCoordinate2D(latitude: 51.4881398, longitude: -0.1866036)
            self.mapView.removeAnnotation(userAnnotation)
            //userLocation = CLLocationCoordinate2D(latitude: locationCoord.latitude, longitude: locationCoord.longitude)

            self.mapView.addAnnotations(self.annotationArray)
   
            // add user location annotation
            userAnnotation.coordinate = userLocation
            userAnnotation.title = "Your Location"
            userAnnotation.subtitle = ""
          
            self.mapView.addAnnotation(userAnnotation)
            
            }
    }
 
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Annotate {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure) as UIView
                
            }
            return view
        }
        return nil
    }
  

    @IBAction func logoutButton(_ sender: AnyObject) {
        
        locationManager.stopUpdatingLocation()
        PFUser.logOut()
        print("logged out")
        dismiss(animated: true, completion: nil)
    }
 
}


// annotations
class Annotate: NSObject, MKAnnotation {
    
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}
    
    

/*
    
 // AUDIO
    
    func findAudio() {
        // find audio if current location is nearby
        let query = PFQuery(className: "POI")
        if let latitude = (PFUser.current()?["location"] as? PFGeoPoint)?.latitude {
            if let longitude = (PFUser.current()?["location"] as? PFGeoPoint)?.longitude {
                // filter out the POI nearby user location
                query.whereKey("coordinates", withinGeoBoxFromSouthwest: PFGeoPoint(latitude: latitude - 0.012, longitude: longitude - 0.012), toNortheast: PFGeoPoint(latitude: latitude + 0.012, longitude: longitude + 0.012))
                
                query.findObjectsInBackground(block: { (objects, error) in
                    if error != nil {
                        print("There was an error")
                    } else {
                        if let clips = objects {
                            print("Clips found")
                            for clip in clips {
                                if let audioClip = clip["audio"] as! PFFile? {
                                    audioClip.getDataInBackground(block: {
                                        
                                        (data, error) in
                                        
                                        print("Size: \(data!.count)")
                                        
                                        if error != nil {
                                            print("No audio found")
                                        } else {
                                            do {
                                                 self.audioPlayer = try AVAudioPlayer(data: data!, fileTypeHint: AVFileTypeMPEGLayer3)
                                                self.playerArray.append(self.audioPlayer)
                                                self.audioDuration = self.audioPlayer.duration
                                                self.scrubber.maximumValue = Float(self.audioDuration)
                                            } catch {
                                                print(error)
                                            }
                                            self.audioArray.append(data!)
                                            
                                            print("Please find audio array here \(self.audioArray)")
                                            
                                        }
                                    })
                                }
                            }
                            
                        } else { print("no clips found") }
                    }
                })
            }
        } else { print("No latitude obtained") }
    }
    var playModeOn = false
    
    @IBOutlet var audioDescriptionLabel: UILabel!
    func updateSlider() {
        scrubber.value = Float(audioPlayer.currentTime)
    }
    @IBOutlet var playButtonLabel: UIButton!
    @IBAction func playAudioButton(_ sender: AnyObject) {
        if playModeOn {
            pauseAudio()
            playButtonLabel.setTitle("Play", for: .normal)
            playModeOn = false
        } else {
            playAudio()
            playButtonLabel.setTitle("Pause", for: .normal)
            playModeOn = true
        }
    }
    @IBAction func scrubberChanged(_ sender: AnyObject) {     
        audioPlayer.currentTime = TimeInterval(scrubber.value)
    }

    func playAudio() {
/*
        self.audioPlayer.volume = 1.0
        self.audioPlayer.play()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
        audioDescriptionLabel.text = ""
        print("Playing clip")
        print(self.playerArray)
 */
        
        self.playerArray[0].play()
        
    }
    func pauseAudio() {
        audioPlayer.pause()
        timer.invalidate()
    }
*/
    
    /*
    //MARK: - Custom Annotation
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        let customPointAnnotation = annotation as! CustomPointAnnotation
        annotationView?.image = UIImage(named: customPointAnnotation.pinCustomImageName)
        
        print("color annotation")
        return annotationView
    }
*/
    


