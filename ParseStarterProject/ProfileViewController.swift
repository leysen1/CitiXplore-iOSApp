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

class ProfileViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate {

    var totalLondonPOIs = Double()
    var completedLondonPOIs = Double()
    var totalarea1POIs = Double()
    var completedarea1POIs = Double()
    var totalarea2POIs = Double()
    var completedarea2POIs = Double()
    var percentage = Int()
    var email = String()
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var LondonCompletedLabel: UILabel!
    @IBOutlet weak var areaCompletedLabel1: UILabel!
    @IBOutlet weak var areaCompletedLabel2: UILabel!
    @IBOutlet var commentEntry: UITextView!
    
    @IBOutlet weak var recent1: UILabel!
    @IBOutlet weak var recent2: UILabel!
    @IBOutlet weak var recent3: UILabel!
    @IBOutlet weak var recent4: UILabel!
    
    @IBOutlet weak var submitCommentLabel: UIButton!
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
        }))
        self.present(alert, animated: true, completion: nil)
    }

    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("profile email \(email)")
        self.emailLabel.text = email

        let dismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(tap))
        view.addGestureRecognizer(dismissKeyboard)
        
        recentVisits()
        
        fetchPOIInfo { (Bool) in
            
            if self.totalLondonPOIs != 0 {
                var percentageTemp = self.completedLondonPOIs / self.totalLondonPOIs
                percentageTemp = round(percentageTemp * 100)
                self.percentage = Int(percentageTemp)
            } else {
                self.percentage = 0
            }
            
            self.LondonCompletedLabel.text = "You have completed \(self.percentage)% of our London POIs."
        }
        
        commentEntry.layer.cornerRadius = 5
        commentEntry.layer.masksToBounds = true
        submitCommentLabel.layer.cornerRadius = 5
        submitCommentLabel.layer.masksToBounds = true
        
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
    
    func recentVisits() {
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: email)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("Error")
            } else {
                if let objects = objects {
                    for object in objects {
                        if let tempCompleted = object["completed"] as? [String] {
                            let i: Int = tempCompleted.count - 1
                            if i > -1 {
                                self.recent1.text = tempCompleted[i]
                            }
                            if i > 0 {
                                self.recent2.text = tempCompleted[i-1]
                            }
                            if i > 1 {
                                self.recent3.text = tempCompleted[i-2]
                            }
                            if i > 2 {
                                self.recent4.text = tempCompleted[i-3]
                            }
                        }
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func keyboardWillShow(notification: NSNotification) {
        print("keyboard shown")
    }
    
    
    @IBAction func logout(_ sender: AnyObject) {
        
        Parse.cancelPreviousPerformRequests(withTarget: self)
        PFUser.logOut()
        print("logged out")
        dismiss(animated: true, completion: nil)
        
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
    
    }
    
    func tap(gesture: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 1, delay: 1, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (completed) in
            self.commentEntry.resignFirstResponder()
        })
    }
    

    


}
