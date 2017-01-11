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
import AudioToolbox

var ratedPOI = String()

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // set up variable
    var locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    var email = String()
    var userAnnotation = MKPointAnnotation()
    var annotationTitle = [String]()
    var annotationAddress = [String]()
    var annotationLocation = [CLLocationCoordinate2D]()
    var MKPinColorArray = [MKPinAnnotationColor]()
    var chosenPOI = String()
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var arrowImage: UIImageView!
    
    var activityIndicator = UIActivityIndicatorView()

    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.findPOIs(completion: { (Bool) in
                self.addAnnotationToMap()
                print("reloading Annotations")
            })
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }

    var timer = Timer()
    
    
    // functions
    
    func updateTimer() {
        // updates location every 10 seconds
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(callUpdateLocation), userInfo: nil, repeats: true)
    }
    
    func callUpdateLocation() {
        locationManager.startUpdatingLocation()
        
        self.saveUserLocation(completion: { (Bool) in
            self.locationManager.stopUpdatingLocation()
        })
        
        if annotationTitle.count > 0 {
            // do nothing
        } else {
            findPOIs(completion: { (Bool) in
                self.addAnnotationToMap()
                print("attempted to reload Annotations")
            })
        }
        
        mapView.reloadInputViews()
        print("updated")
        
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationCoord = manager.location?.coordinate {
            
            userLocation = CLLocationCoordinate2D(latitude: locationCoord.latitude, longitude: locationCoord.longitude)

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self.checkNearPOI()
                print("checked for nearby POIs")
            }
            
        }
    }

    
    func saveUserLocation(completion: @escaping (_ result: Bool)->()) {
        
        // save user location
        if let tempUserLocation = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude) as? PFGeoPoint {
            
            PFUser.current()?["location"] = tempUserLocation
            PFUser.current()?.saveInBackground(block: { (success, error) in
                if error != nil {
                    print("error")
                } else {
                    print("saved user location")
                    if let items = (self.navigationController?.toolbarItems) {
                        for item: UIBarButtonItem in items {
                            item.isEnabled = true
                        }
                    }
                    completion(true)
                }
            })

        } else {
            completion(true)
        }
        
    }
    
    func findPOIs(completion: @escaping (_ result: Bool)->()) {
        // find all POIs

        let query = PFQuery(className: "POI")
        query.whereKey("area", equalTo: "Kensington and Chelsea")
        query.findObjectsInBackground(block: { (objects, error) in
            if error != nil {
                print("could not get objects")
            } else {
                if let poiLocations = objects {
                    self.annotationTitle.removeAll()
                    self.annotationAddress.removeAll()
                    self.annotationLocation.removeAll()
                    self.MKPinColorArray.removeAll()
                    var completedArray: [String]?
                    var i = 0
                    for poiLocation in poiLocations {
                        completedArray?.removeAll()
                        if let tempTitle = poiLocation["name"] as? String {
                            self.annotationTitle.append(tempTitle)
                        } else {
                            self.annotationTitle.append(" ")
                        }
                        if let tempAddress = poiLocation["address"] as? String {
                            self.annotationAddress.append(tempAddress)
                        } else {
                            self.annotationAddress.append(" ")
                        }
                        
                        if let tempLocation = poiLocation["coordinates"] as? PFGeoPoint {
                            self.annotationLocation.append(CLLocationCoordinate2D(latitude: tempLocation.latitude, longitude: tempLocation.longitude))
                        } else {
                            self.annotationLocation.append(CLLocationCoordinate2D(latitude: 0, longitude: 0))
                        }
                        completedArray = poiLocation["completed"] as? [String]
                        if completedArray != nil {
                        if (completedArray?.contains(self.email))! {
                            self.MKPinColorArray.append(MKPinAnnotationColor.green)
                        }
                        else {
                            self.MKPinColorArray.append(MKPinAnnotationColor.red)
                            }
                        } else {
                            self.MKPinColorArray.append(MKPinAnnotationColor.red)
                        }
                        
                        i += 1
                        if i == poiLocations.count {
                            completion(true)
                            print("compeleted findPOIs")
                        }
                        
                    }
                    
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                } else {
                    completion(true)
                }
            }
            
        })
    }
    
    func addAnnotationToMap() {
        if annotationTitle.count > 0 {
            for item in annotationTitle {
                let annotate = Annotate(title: item, locationName: annotationAddress[annotationTitle.index(of: item)!], coordinate: CLLocationCoordinate2D(latitude: annotationLocation[annotationTitle.index(of: item)!].latitude, longitude: annotationLocation[annotationTitle.index(of: item)!].longitude), color: MKPinColorArray[annotationTitle.index(of: item)!])
                print("annotate \(annotate)")
                mapView.addAnnotation(annotate)
                mapView.reloadInputViews()
            }
        }
    }
    
    func checkNearPOI() {
        
        // if current location is near POI, then check off list
        
        let query = PFQuery(className: "POI")
        if let email = PFUser.current()?.username {
            query.whereKey("completed", notContainedIn: [email])
            query.whereKey("coordinates", nearGeoPoint: PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude), withinKilometers: 0.05)
            query.findObjectsInBackground { (objects, error) in
                if error != nil {
                    print("error")
                } else {
                    if let objects = objects {
                        for object in objects {
                            print("object here \(object)")
                            object.addUniqueObject(email, forKey: "completed")
                            object.saveInBackground()
                            print("object saved")
                            if let tempName = object["name"] as? String {
                                if let tempArea = object["area"] as? String {
                                    self.createAlert(title: "\(tempName), \(tempArea) Completed", message: "Make you sure listen to the audio!")
                                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                }
                            }
                        }
                    }
                }
            }
            
        } else {
            print("could not reach Parse")
        }
        
    }

    // load view

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Map"

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let emailTemp = (PFUser.current()?.username!) {
            email = emailTemp
            print("email \(email)")
        }
        
        saveUserLocation { (Bool) in
            self.findPOIs(completion: { (Bool) in
            })
            let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
            self.mapView.setRegion(region, animated: false)
        }

        
        if let items = (self.navigationController?.toolbarItems) {
            for item: UIBarButtonItem in items {
                item.isEnabled = false
            }
        }

    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        

        mapView.delegate = self
        mapView.showsUserLocation = true
        
        updateTimer()
        
        findPOIs { (Bool) in
            self.addAnnotationToMap()
        }
        
        /*
        // annotation
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
           self.addAnnotationToMap()
            print("map view \(self.mapView.annotations)")
        }
 */
        
        // arrow if signup
        animateArrow()
        
        if ratedPOI != "" {
            print("rated POI \(ratedPOI)")
            if let indexNo = self.annotationTitle.index(of: ratedPOI) {
                let ratedPOILocation = self.annotationLocation[indexNo]
                let region = MKCoordinateRegion(center: ratedPOILocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                self.mapView.setRegion(region, animated: false)
            }

        } else {
            let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
            self.mapView.setRegion(region, animated: false)
        }
        
        
 
    }
 
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("authorisation changed")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.5) {
            let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
            self.mapView.setRegion(region, animated: false)
        }

    }
    
    func animateArrow() {
            if helpClicked == false {
                arrowImage.image = UIImage(named: "redarrow.png")
                arrowImage.alpha = 0
                UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn, .repeat, .autoreverse], animations: {
                    self.arrowImage.alpha = 1.0
                    })
            } else {
                arrowImage.alpha = 0
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
                view.pinColor = annotation.color
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure) as UIView
                
            }
            return view
        }
        return nil
    }
    

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("tapped")
        
        if let annotation = view.annotation as? Annotate {
            print("Your annotation title: \(annotation.title)")
            if let title = annotation.title {
                chosenPOI = title
                performSegue(withIdentifier: "toSinglePOI", sender: self)
            }
            
        }
        
    }
    
    @IBAction func aboutPopup(_ sender: AnyObject) {
        
        if helpClicked == false {
            helpClicked = true
            animateArrow()
            
        }
        
        let popupAbout = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "aboutPopupID") as! AboutViewController
        self.addChildViewController(popupAbout)
        popupAbout.view.frame = self.view.frame
        self.view.addSubview(popupAbout.view)
        popupAbout.didMove(toParentViewController: self)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
        timer.invalidate()
        ratedPOI = ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toSinglePOI") {
            let singlePOI = segue.destination as! SinglePOIViewController
            singlePOI.name = chosenPOI
            
        }
        if (segue.identifier == "areaSegue") {
            let AreaVC = segue.destination as! AreaTableViewController
            AreaVC.userLocation = self.userLocation
            AreaVC.email = self.email
        }
        
        if (segue.identifier == "toFavs") {
            let favVC = segue.destination as! FavouritesViewController
            favVC.email = self.email
        }
        
        if (segue.identifier == "toProfile") {
            let profVC = segue.destination as! ProfileViewController
            profVC.email = self.email
        }
        
       
        
        
    }
    
 
}

// annotations
class Annotate: NSObject, MKAnnotation {
    
    let title: String?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    var color: MKPinAnnotationColor
    
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D, color: MKPinAnnotationColor) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        self.color = color
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}
    
