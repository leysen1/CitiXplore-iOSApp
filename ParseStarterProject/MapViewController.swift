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
    let serialQueue = DispatchQueue(label: "label")

    var tappedPlaceForMapMV: String?
    
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
                if let poiLocations = objects {
                    var completedArray: [String]?
                    for poiLocation in poiLocations {
                        completedArray?.removeAll()
                        self.annotationTitle.append((poiLocation["name"] as? String)!)
                        self.annotationAddress.append((poiLocation["address"] as? String)!)
                        self.annotationLocation.append(CLLocationCoordinate2D(latitude: (poiLocation["coordinates"] as AnyObject).latitude, longitude: (poiLocation["coordinates"] as AnyObject).longitude))
                        completedArray = (poiLocation["completed"] as? [String])
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

                    print("here")
                    print(self.annotationTitle)
                    print(self.annotationAddress)
                    print(self.annotationLocation)
                    print(self.MKPinColorArray)
                    
                }
            })
        })
            
        let delayInSeconds = 1.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
            // set map view
            if self.tappedPlaceForMapMV != nil {
                // centre on specific POI
                let item = self.tappedPlaceForMapMV!
                let POILocation = CLLocationCoordinate2D(latitude: self.annotationLocation[self.annotationTitle.index(of: item)!].latitude, longitude: self.annotationLocation[self.annotationTitle.index(of: item)!].longitude)
                let region = MKCoordinateRegion(center: POILocation, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                self.mapView.setRegion(region, animated: false)
                
            } else {
                // centre on user
                let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
                self.mapView.setRegion(region, animated: false)
            }

            }
 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // annotation
        serialQueue.sync(execute: {
            
            if tappedPlaceForMapMV != nil {
                // we went through a specific POI cell, only show one POI
                let item = self.tappedPlaceForMapMV!
                let annotate = Annotate(title: item, locationName: annotationAddress[annotationTitle.index(of: item)!], coordinate: CLLocationCoordinate2D(latitude: annotationLocation[annotationTitle.index(of: item)!].latitude, longitude: annotationLocation[annotationTitle.index(of: item)!].longitude), color: MKPinColorArray[annotationTitle.index(of: item)!])
                mapView.addAnnotation(annotate)
            } else {
                // show all POIs
                for item in annotationTitle {
                    let annotate = Annotate(title: item, locationName: annotationAddress[annotationTitle.index(of: item)!], coordinate: CLLocationCoordinate2D(latitude: annotationLocation[annotationTitle.index(of: item)!].latitude, longitude: annotationLocation[annotationTitle.index(of: item)!].longitude), color: MKPinColorArray[annotationTitle.index(of: item)!])
                    print("annotate \(annotate)")
                    mapView.addAnnotation(annotate)
                }
            }

        })
        
        serialQueue.sync(execute: {

            mapView.delegate = self
            mapView.showsUserLocation = true
        })
        
        print("tapped \(tappedPlaceForMapMV)")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        tappedPlaceForMapMV?.removeAll()
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
    
