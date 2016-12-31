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

class ProfileViewController: UIViewController {

    var totalPOIs = Double()
    var completedPOIs = Double()
    var percentage = Int()
    var email = String()
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var completedLabel: UILabel!
    @IBOutlet var commentEntry: UITextView!
    
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
        


        fetchPOIInfo { (Bool) in
            
            if self.totalPOIs != 0 {
                var percentageTemp = self.completedPOIs / self.totalPOIs
                percentageTemp = round(percentageTemp * 100)
                self.percentage = Int(percentageTemp)
            } else {
                self.percentage = 0
            }
            
            self.completedLabel.text = "You have completed \(self.percentage)% of our London POIs."
        }
    }
    
    func fetchPOIInfo(completion: @escaping (_ result: Bool)->()) {
        
        var i = 0
        let query = PFQuery(className: "POI")
        
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    self.totalPOIs = Double(objects.count)
                    i += 1
                    if i == 2 {
                        completion(true)
                    }
                } else {
                    completion(true)
                }
            }
        }
        
        let query2 = PFQuery(className: "POI")
        query2.whereKey("completed", contains: email)
        query2.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    self.completedPOIs = Double(objects.count)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (completed) in
            self.commentEntry.resignFirstResponder()
        })
    }
    

    


}
