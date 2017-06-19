//
//  ProfileViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 27/10/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import FBSDKLoginKit

protocol logoutDelegate {
    func logoutClicked(loggingOut: Bool)
}


class ProfileViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var activityIndicator = UIActivityIndicatorView()
    var delegate: logoutDelegate? = nil
    var totalLondonPOIs = Double()
    var completedLondonPOIs = Double()
    var percentage = Int()
    var email = String()
    var areasArray = [String]()
    var poiNoInEachArray = [Double]()
    var poiNoCompletedInEachArray = [Double]()

    @IBOutlet var profile: UIImageView!
    @IBOutlet var cityLabel: UILabel!
    @IBAction func profileImageButton(_ sender: Any) {
        print("button pressed")
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    @IBOutlet weak var summary1: UILabel!
    @IBOutlet weak var summary2: UILabel!
    @IBOutlet weak var summary3: UILabel!
    @IBOutlet var summary4: UILabel!
    
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var commentEntry: UITextView!
    @IBOutlet weak var recent1: UILabel!
    @IBOutlet weak var recent2: UILabel!
    @IBOutlet weak var recent3: UILabel!
    @IBOutlet weak var submitCommentLabel: UIButton!
    @IBOutlet weak var navBarBox: UINavigationBar!
    
    @IBOutlet weak var summaryHeader: UILabel!
    @IBOutlet weak var recentVisitsHeader: UILabel!
    @IBOutlet weak var feedbackHeader: UILabel!
    // Buttons 

    @IBAction func submitComment(_ sender: AnyObject) {
        
        if commentEntry.text != "" {
            let query = PFQuery(className: "_User")
            query.whereKey("username", contains: email)
            query.findObjectsInBackground(block: { (objects, error) in
                if error != nil {
                    print("error")
                } else {
                    if let objects = objects {
                        for object in objects {
                            object.addUniqueObject(self.commentEntry.text, forKey: "feedback")
                            object.saveInBackground()
                            print("comment saved")
                            self.createAlert(title: "Feedback", message: "We have received your comments. Thank you!")
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func logout(_ sender: AnyObject) {
        
        Parse.cancelPreviousPerformRequests(withTarget: self)
        PFUser.logOut()
        print("logged out")
        
        if delegate != nil {
            delegate?.logoutClicked(loggingOut: true)
        }
        dismiss(animated: true, completion: nil)
        
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()


    }
    
    // Loading 
    
    override func viewDidLoad() {
        super.viewDidLoad()

        summaryHeader.text = "Loading..."
        // Aesthetics
        self.navigationController?.navigationBar.topItem?.title = "Profile"
        commentEntry.layer.cornerRadius = 5
        commentEntry.layer.masksToBounds = true
        submitCommentLabel.layer.cornerRadius = 5
        submitCommentLabel.layer.masksToBounds = true
        profile.image = UIImage(named: "star.png")
        
        delegate = ViewController()
        
        let dismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(tap))
        view.addGestureRecognizer(dismissKeyboard)
        
        getEmail { (Bool) in
            self.fetchAreas(completion: { (Bool) in
                self.getPhoto()
                self.recentVisits()
                self.fetchPOIInfo { (Bool) in
                    self.populateLabels()
                }
            })
        
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        profile.layer.masksToBounds = true
        profile.layer.cornerRadius = 50
        
        navBarBox.titleTextAttributes = [NSFontAttributeName : UIFont(name: "AvenirNext-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20), NSForegroundColorAttributeName: UIColor(red: 23, green: 31, blue: 149, alpha: 1)]
        view.backgroundColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        navBarBox.barTintColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        navBarBox.shadowImage = UIImage()
        navBarBox.setBackgroundImage(UIImage(), for: .default)
        
    }
    
    // Functions

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            /* how big the image size (for Parse has to be under 10MB)
             var imageSize = Double(NSData(data: UIImagePNGRepresentation(image)!).length)
             print("PNG size of image in MB: ", imageSize/(1024*1024),"MB")
             print("PNG size of image in MB: \(imageSize / (1024*1024))")
             imageSize = Double(NSData(data: UIImageJPEGRepresentation((image), 1)!).length)
             print("JPG size at 1.0 of image in MB: ", imageSize / (1024*1024))
             imageSize = Double(NSData(data: UIImageJPEGRepresentation(image, 0.5)!).length)
             print("JPG size at .5 of image in KB: ", imageSize / (1024))
             */
            
            profile.image = image
            
            let query = PFQuery(className: "_User")
            query.whereKey("username", equalTo: email)
            query.findObjectsInBackground { (objects, error) in
                if error != nil {
                    print("error")
                } else {
                    if let objects = objects {
                        for object in objects {
                            let imageData = UIImageJPEGRepresentation(self.profile.image!, 0.8)
                            let imageFile = PFFile(name: "profile.png", data: imageData!)
                            object.setObject(imageFile!, forKey: "photo")
                            object.saveInBackground()
                            print("saved photo")
                        }
                    }
                }
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func getEmail(completion: @escaping (_ result: Bool)->()) {
        if let tempEmail = PFUser.current()?.username! {
            self.emailLabel.text = tempEmail
            email = tempEmail
            completion(true)
        }

    }
    
    func getPhoto() {
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: email)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    for object in objects {
                        if let imageFile = object["photo"] as? PFFile {
                            imageFile.getDataInBackground(block: { (data, error) in
                                if let imageData = data {
                                    if let downloadedImage = UIImage(data: imageData) {
                                        self.profile.image = downloadedImage
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
    }
    
    func fetchAreas(completion: @escaping (_ result: Bool)->()) {
        let query = PFQuery(className: "POI")
        query.whereKey("city", equalTo: "London")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        if let tempArea = object["area"] as? String {
                            if self.areasArray.contains(tempArea) == false {
                                self.areasArray.append(tempArea)
                                self.poiNoInEachArray.append(0)
                                self.poiNoCompletedInEachArray.append(0)
                            }
                        }
                        i += 1
                        if i == objects.count {
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    func fetchPOIInfo(completion: @escaping (_ result: Bool)->()) {
        
        var i = 0
        // total number
        let query = PFQuery(className: "POI")
        query.whereKey("city", equalTo: "London")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    self.totalLondonPOIs = Double(objects.count)
                    for object in objects {
                        if let tempArea = object["area"] as? String {
                            self.poiNoInEachArray[self.areasArray.index(of: tempArea)!] += 1
                        }
                        
                    }
                    i += 1
                    if i == 2 {
                        completion(true)
                    }
                } else {
                    completion(true)
                }
            }
        }
        
        // completed number
        let query2 = PFQuery(className: "POI")
        query2.whereKey("city", equalTo: "London")
        query2.whereKey("completed", contains: email)
        query2.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    self.completedLondonPOIs = Double(objects.count)
                    for object in objects {
                        if let tempArea = object["area"] as? String {
                            self.poiNoCompletedInEachArray[self.areasArray.index(of: tempArea)!] += 1
                        }
                        
                    }
                    i += 1
                    if i == 2 {
                        completion(true)
                        
                    }
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func populateLabels() {
        summaryHeader.text = "COMPLETED"
        print("completed in London")
        print(self.completedLondonPOIs)
        
        if self.totalLondonPOIs != 0 {
            var percentageTemp = self.completedLondonPOIs / self.totalLondonPOIs
            percentageTemp = round(percentageTemp * 100)
            self.percentage = Int(percentageTemp)
        } else {
            self.percentage = 0
        }
        let tempCompletedArray = poiNoCompletedInEachArray.sorted()
        print(tempCompletedArray)
        let tempAreasArray = areasArray
        let tempPoiNoArray = poiNoInEachArray
        
        var j = 0
        for item in poiNoCompletedInEachArray {
            let indexNo = tempCompletedArray.index(of: item)
            areasArray[indexNo!] = tempAreasArray[poiNoCompletedInEachArray.index(of: item)!]
            poiNoInEachArray[indexNo!] = tempPoiNoArray[poiNoCompletedInEachArray.index(of: item)!]
            j += 1
            if j == poiNoCompletedInEachArray.count {
                // finish orangising data
                poiNoCompletedInEachArray = tempCompletedArray
                let k = areasArray.count - 1
                
                if poiNoCompletedInEachArray[k] == 0 {
                    self.summary1.text = "You haven't visited any POIs yet"
                } else {
                    let summary1Percentage = round((poiNoCompletedInEachArray[k] / poiNoInEachArray[k]) * 100)
                    self.summary1.text = "\(Int(summary1Percentage))% of \(areasArray[k])   (\(Int(self.poiNoCompletedInEachArray[k]))/\(Int(self.poiNoInEachArray[k])))"
                    
                    if k-1 >= 0 {
                        let summary2Percentage = round((poiNoCompletedInEachArray[k-1] / poiNoInEachArray[k-1]) * 100)
                        self.summary2.text = "\(Int(summary2Percentage))% of \(areasArray[k-1])   (\(Int(self.poiNoCompletedInEachArray[k-1]))/\(Int(self.poiNoInEachArray[k-1])))"
                    }
                    
                    if k-2 >= 0 {
                        let summary3Percentage = round((poiNoCompletedInEachArray[k-2] / poiNoInEachArray[k-2]) * 100)
                        self.summary3.text = "\(Int(summary3Percentage))% of \(areasArray[k-2])   (\(Int(self.poiNoCompletedInEachArray[k-2]))/\(Int(self.poiNoInEachArray[k-2])))"
                    }
                    if k-3 >= 0 {
                        let summary4Percentage = round((poiNoCompletedInEachArray[k-3] / poiNoInEachArray[k-3]) * 100)
                        self.summary4.text = "\(Int(summary4Percentage))% of \(areasArray[k-3])   (\(Int(self.poiNoCompletedInEachArray[k-3]))/\(Int(self.poiNoInEachArray[k-3])))"
                    }
                    
                }
            }
        }
    }
    
    func recentVisits() {
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: email)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("Error")
            } else {
                if let objects = objects {
                    print("number of objects \(objects.count)")
                    for object in objects {
                        if let tempCompleted = object["completed"] as? [String] {
                            print("tempcompleted \(tempCompleted)")
                            let i: Int = tempCompleted.count - 1
                            print("i \(i)")
                            if i > -1 {
                                self.recent1.text = tempCompleted[i]
                            }
                            if i > 0 {
                                self.recent2.text = tempCompleted[i-1]
                            }
                            if i > 1 {
                                self.recent3.text = tempCompleted[i-2]
                            }
                        } else {
                            self.recent1.text = "Please visit a POI soon!"
                        }
                    }
                }
            }
        }
    }

    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func keyboardWillShow(notification: NSNotification) {
        print("keyboard shown")
    }
    
    func tap(gesture: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 1, delay: 1, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (completed) in
            self.commentEntry.resignFirstResponder()
        })
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
