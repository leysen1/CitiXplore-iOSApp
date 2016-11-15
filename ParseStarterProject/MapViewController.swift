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
    
    var annotationTitle = [String]()
    var annotationAddress = [String]()
    var annotationLocation = [CLLocationCoordinate2D]()
    var annotationColor = [String]()
    let serialQueue = DispatchQueue(label: "label")

    @IBOutlet var mapView: MKMapView!

    @IBAction func areaView(_ sender: AnyObject) {
        navigationController?.dismiss(animated: true, completion: {
            
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationCoord = manager.location?.coordinate {
            
            userLocation = CLLocationCoordinate2D(latitude: 51.4881398, longitude: -0.1866036)
            print("location: \(locationCoord.latitude)")
            //userLocation = CLLocationCoordinate2D(latitude: locationCoord.latitude, longitude: locationCoord.longitude)
            userAnnotation.coordinate = userLocation
            userAnnotation.title = "Your Location"
            userAnnotation.subtitle = ""
            self.mapView.addAnnotation(userAnnotation)
        }
    }
 
    
        override func viewDidLoad() {
        super.viewDidLoad()
            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            
            print("location updating")
            
            
            
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
                    for poiLocation in poiLocations {
                        self.annotationTitle.append((poiLocation["name"] as? String)!)
                        self.annotationAddress.append((poiLocation["address"] as? String)!)
                        self.annotationLocation.append(CLLocationCoordinate2D(latitude: (poiLocation["coordinates"] as AnyObject).latitude, longitude: (poiLocation["coordinates"] as AnyObject).longitude))
                        self.annotationColor.append("purple")
                        
                    }
                    print("here")
                    print(self.annotationTitle)
                    print(self.annotationAddress)
                    print(self.annotationLocation)
                    print(self.annotationColor)
                    
                }
            })
        })

        // set map view
        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
        self.mapView.setRegion(region, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // annotation
        serialQueue.sync(execute: {
            for item in annotationTitle {
                let annotate = Annotate(title: item, locationName: annotationAddress[annotationTitle.index(of: item)!], coordinate: CLLocationCoordinate2D(latitude: annotationLocation[annotationTitle.index(of: item)!].latitude, longitude: annotationLocation[annotationTitle.index(of: item)!].longitude), color: MKPinAnnotationColor.purple)
                print("annotate \(annotate)")
                mapView.addAnnotation(annotate)
            }
        })
        
        serialQueue.sync(execute: {

            mapView.delegate = self
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
    
