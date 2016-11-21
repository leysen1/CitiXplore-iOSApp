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

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 51.4881398, longitude: -0.1866036)
    
    let username = (PFUser.current()?.username!)!
    var userAnnotation = MKPointAnnotation()
    var annotationTitle = [String]()
    var annotationAddress = [String]()
    var annotationLocation = [CLLocationCoordinate2D]()
    var MKPinColorArray = [MKPinAnnotationColor]()
    var chosenPOI = String()
    let serialQueue = DispatchQueue(label: "label")
    
    var activityIndicator = UIActivityIndicatorView()
    
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    

    @IBOutlet var mapView: MKMapView!

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationCoord = manager.location?.coordinate {
            

            // userLocation = CLLocationCoordinate2D(latitude: 51.4885039, longitude: -0.1880413)
            userLocation = CLLocationCoordinate2D(latitude: locationCoord.latitude, longitude: locationCoord.longitude)

            checkNearPOI()
            
        }
    }
 
    
        override func viewDidLoad() {
        super.viewDidLoad()

            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()

            self.title = "Map"
            
            //Spinner
            activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            activityIndicator.startAnimating()
            view.addSubview(activityIndicator)
            UIApplication.shared.beginIgnoringInteractionEvents()

            
            serialQueue.sync(execute: {
            // save user location
            PFUser.current()?["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
            PFUser.current()?.saveInBackground(block: { (success, error) in
                if error != nil {
                    print(error)
                } else {
                    print("saved user location")
                }
            })
                })
            
            serialQueue.sync(execute: {
            // find all POIs
            let query = PFQuery(className: "POI")
            query.findObjectsInBackground(block: { (objects, error) in
                if error != nil {
                    print("could not get objects")
                } else {
                if let poiLocations = objects {
                    var completedArray: [String]?
                    for poiLocation in poiLocations {
                        completedArray?.removeAll()
                        self.annotationTitle.append((poiLocation["name"] as? String)!)
                        self.annotationAddress.append((poiLocation["address"] as? String)!)
                        self.annotationLocation.append(CLLocationCoordinate2D(latitude: (poiLocation["coordinates"] as AnyObject).latitude, longitude: (poiLocation["coordinates"] as AnyObject).longitude))
                        completedArray = poiLocation["completed"] as? [String]
                        if completedArray != nil {
                            if (completedArray?.contains(self.username))! {
                                self.MKPinColorArray.append(MKPinAnnotationColor.green)
                            }
                            else {
                                self.MKPinColorArray.append(MKPinAnnotationColor.red)
                            }
                        } else {
                            self.MKPinColorArray.append(MKPinAnnotationColor.red)
                        }
 
                    }
                    
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
                }
                
            })
        })
            
        let delayInSeconds = 1.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
 
                // centre on user
                let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                self.mapView.setRegion(region, animated: false)

            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // annotation
        serialQueue.sync(execute: {

                for item in annotationTitle {
                    let annotate = Annotate(title: item, locationName: annotationAddress[annotationTitle.index(of: item)!], coordinate: CLLocationCoordinate2D(latitude: annotationLocation[annotationTitle.index(of: item)!].latitude, longitude: annotationLocation[annotationTitle.index(of: item)!].longitude), color: MKPinColorArray[annotationTitle.index(of: item)!])
                    print("annotate \(annotate)")
                    mapView.addAnnotation(annotate)
            }
             mapView.reloadInputViews()

        })
        
        serialQueue.sync(execute: {

            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.reloadInputViews()
        })
        
        
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
    
    func checkNearPOI() {
        
        // if current location is near POI, then check off list
        
        let query = PFQuery(className: "POI")
        query.whereKey("completed", notContainedIn: [(PFUser.current()?.username!)!])
        query.whereKey("coordinates", nearGeoPoint: PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude), withinKilometers: 0.05)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
            } else {
                if let objects = objects {
                    var checkedItems = [String]()
                    for object in objects {
                        print("object here \(object)")
                        checkedItems.append(object["name"] as! String)
                        object.addUniqueObject((PFUser.current()?.username!)!, forKey: "completed")
                        object.saveInBackground()
                        print("object saved")
                        self.createAlert(title: "\(object["name"] as! String), \(object["area"] as! String) Completed", message: "Make you sure listen to the audio!")
                    }  
                }
            }
        }
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
    
    override func viewDidDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toSinglePOI") {
            let singlePOI = segue.destination as! SinglePOIViewController
            singlePOI.name = chosenPOI
        }
        
        
    }
    
    @IBAction func logout(_ sender: AnyObject) {
        
        Parse.cancelPreviousPerformRequests(withTarget: self)
        PFUser.logOut()
        print("logged out")
        dismiss(animated: true, completion: nil)
        

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
    
