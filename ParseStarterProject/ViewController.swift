/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse
import FBSDKLoginKit
import CoreData

var helpClicked = true

class ViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate {

    @IBOutlet var emailInput: UITextField!
    @IBOutlet var passwordInput: UITextField!
    @IBOutlet var changeModeLabel: UILabel!
    @IBOutlet var loginOrSignupButtonLabel: UIButton!    
    @IBOutlet var changeSignupOrLoginButtonLabel: UIButton!
    
    @IBOutlet weak var heading: UILabel!
    
    var loginMode = true
    var activityIndicator = UIActivityIndicatorView()
    var fbLoginPressed = Bool()
    
    let moc = DataController().managedObjectContext
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func loginOrSignup(sender: AnyObject) {
        //Spinner
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        if isValidEmail(testStr: emailInput.text!) {
            print("Valid Email")
            
            if loginMode == true {
                // log in user
                print("logging in")
                PFUser.logInWithUsername(inBackground: emailInput.text!, password: passwordInput.text!, block: { (user, error) in
                    
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    
                    if error != nil {
                        
                        var displayErrorMessage = "Please try again later"
                        let error = error as NSError?
                        if let errorMessage = error?.userInfo["error"] as? String {
                            displayErrorMessage = errorMessage
                        }
                        self.createAlert(title: "Log In Error", message: displayErrorMessage)
                        
                    } else {
                        print("Logged in")
                        self.performSegue(withIdentifier: "toMapView", sender: self)
                        
                        // check if shortcut created
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Shortcuts")
                        do {
                            let fetch = try self.moc.fetch(request) as! [Shortcuts]
                            if fetch.count > 0 {
                                // already have a shortcut
                                print("already have shortcut")
                            } else {
                                let entity = NSEntityDescription.insertNewObject(forEntityName: "Shortcuts", into: self.moc) as! Shortcuts
                                entity.setValue(self.emailInput.text, forKey: "username")
                                entity.setValue(self.passwordInput.text, forKey: "password")
                                entity.setValue("none", forKey: "area")
                                entity.setValue("none", forKey: "city")
                                
                                do {
                                    try self.moc.save()
                                    print("saved shortcut")
                                } catch {
                                    fatalError("Failure to save context: \(error)")
                                }
                            }
                        } catch {
                            
                        }

                        
                        
                    }
                })
                
            } else if loginMode == false {
                // sign up user
                if emailInput.text == "" {
                    createAlert(title: "Missing Field", message: "Please enter your email.")
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                } else {
                let user = PFUser()
                user.password = passwordInput.text
                user.username = emailInput.text
                
                let acl = PFACL()
                acl.getPublicWriteAccess = true
                acl.getPublicReadAccess = true
                user.acl = acl
                
                user.signUpInBackground(block: { (success, error) in
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    
                    if error != nil {
                        var displayErrorMessage = "Please try again later"
                        let error = error as NSError?
                        if let errorMessage = error?.userInfo["error"] as? String {
                            displayErrorMessage = errorMessage
                        }
                        self.createAlert(title: "Sign Up Error", message: displayErrorMessage)
                    } else {
                        print("user signed up")
                        self.performSegue(withIdentifier: "toMapView", sender: self)
                        
                        // save details to shortcut
                        
                        let entity = NSEntityDescription.insertNewObject(forEntityName: "Shortcuts", into: self.moc) as! Shortcuts
                        entity.setValue(self.emailInput.text, forKey: "username")
                        entity.setValue(self.passwordInput.text, forKey: "password")
                        entity.setValue("none", forKey: "area")
                        entity.setValue("none", forKey: "city")

                        do {
                            try self.moc.save()
                            print("saved shortcut")
                        } catch {
                            fatalError("Failure to save context: \(error)")
                        }
                    }
                })
                }
            }
        }   else {
            print("invalid Email")
            createAlert(title: "Invalid Email Address", message: "Please enter a valid email address.")
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }
    
    @IBAction func changeSignupOrLogin(sender: AnyObject) {
        if loginMode == true {
            // change to sign up mode
            loginMode = false
            loginOrSignupButtonLabel.setTitle("Sign Up", for: [])
            changeSignupOrLoginButtonLabel.setTitle("Log In", for: [])
            changeModeLabel.text = "Already member?"
            
        } else {
            // change to log in mode
            loginMode = true
            loginOrSignupButtonLabel.setTitle("Log In", for: [])
            changeSignupOrLoginButtonLabel.setTitle("Sign Up", for: [])
            changeModeLabel.text = "Don't have an account?"
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        heading.layer.cornerRadius = 10
        heading.layer.masksToBounds = true
        loginOrSignupButtonLabel.layer.cornerRadius = 5
        loginOrSignupButtonLabel.layer.masksToBounds = true
        
        
      
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (FBSDKAccessToken.current() != nil) {
            if fbLoginPressed == false {
                print("User Logged In")
                self.fbToParse()
            }
            
        } else {
            print("Facebook user not logged in")
            if let currentUser = PFUser.current() {
                if currentUser.email != nil {
                    print("\(currentUser.email) is logged in")
                    self.performSegue(withIdentifier: "toMapView", sender: self)
                    
                } else {
                    print("none logged in")
                    
                    loginMode = true
                    // rid keyboard
                    let dismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(tap))
                    view.addGestureRecognizer(dismissKeyboard)
                    
                    emailInput.delegate = self
                    passwordInput.delegate = self
                    
                    
                    // facebook login
                    
                    let loginButton : FBSDKLoginButton = FBSDKLoginButton()
                    loginButton.readPermissions = ["public_profile", "email"]
                    loginButton.center = view.center
                    loginButton.delegate = self
                    loginButton.translatesAutoresizingMaskIntoConstraints = false
                    self.view.addSubview(loginButton)


                    
                    let centerXConstraint = NSLayoutConstraint(item: loginButton, attribute: .centerX, relatedBy: .equal, toItem: emailInput, attribute: .centerX, multiplier: 1, constant: 0)
                    
                    let centerYConstraint = NSLayoutConstraint(item: loginButton, attribute: .bottom, relatedBy: .equal, toItem: emailInput, attribute: .top, multiplier: 1, constant: -30)
                        
                    self.view.addConstraints([centerXConstraint, centerYConstraint])
   

                    
                    
                    
                }
            } else {
                print("could not reach parse")
            }
        }

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailInput.resignFirstResponder()
        passwordInput.resignFirstResponder()
        return true
    }
    
    func isValidEmail(testStr:String) -> Bool {
        print("validate emilId: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: testStr)
        return result
        
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
        }
        else if result.isCancelled { 
            print("User cancelled login")
        }
        else {
            if result.grantedPermissions.contains("email") {
                print("logged in")
                fbLoginPressed = true
                fbToParse()
            }

        }
    }
    
    func fbToParse() {
        // check if already exists in parse
        //Spinner
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        if let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email,name"]) {
            graphRequest.start(completionHandler: { (connection, result, error) in
                if error != nil {
                    print("error")
                } else {
                    if let userDetails = result as? [String: String] {

                        let query = PFQuery(className: "_User")
                        query.whereKey("username", contains: userDetails["email"])
                        query.findObjectsInBackground(block: { (objects, error) in
                            if error != nil {
                                print("error")
                            } else {
                                if let objects = objects {
                                    print("there are objects")
                                    if objects.count > 0 {
                                        // facebook user already logged in
                                        print("welcome back user")
                                        PFUser.logInWithUsername(inBackground: userDetails["email"]!, password: "password", block: { (user, error) in
                                            
                                            self.activityIndicator.stopAnimating()
                                            UIApplication.shared.endIgnoringInteractionEvents()
                                            
                                            if error != nil {
                                                
                                                var displayErrorMessage = "Please try again later"
                                                let error = error as NSError?
                                                if let errorMessage = error?.userInfo["error"] as? String {
                                                    displayErrorMessage = errorMessage
                                                }
                                                self.createAlert(title: "Log In Error", message: displayErrorMessage)
                                                
                                            } else {
                                                print("Logged in")
                                                self.performSegue(withIdentifier: "toMapView", sender: self)
                                                
                                                // check if shortcut created
                                                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Shortcuts")
                                                do {
                                                    let fetch = try self.moc.fetch(request) as! [Shortcuts]
                                                    if fetch.count > 0 {
                                                        // already have a shortcut
                                                        print("already have shortcut")
                                                    } else {
                                                        let entity = NSEntityDescription.insertNewObject(forEntityName: "Shortcuts", into: self.moc) as! Shortcuts
                                                        entity.setValue(self.emailInput.text, forKey: "username")
                                                        entity.setValue(self.passwordInput.text, forKey: "password")
                                                        entity.setValue("none", forKey: "area")
                                                        entity.setValue("none", forKey: "city")
                                                        
                                                        do {
                                                            try self.moc.save()
                                                            print("saved shortcut")
                                                        } catch {
                                                            fatalError("Failure to save context: \(error)")
                                                        }
                                                    }
                                                } catch {
                                                    
                                                }

                                            }
                                        })
                                    } else {
                                        // facebook user's first log in
                                        // save details to parse
                                        let user = PFUser()
                                        user.username = userDetails["email"]
                                        user.password = "password"
                                        
                                        
                                        let acl = PFACL()
                                        acl.getPublicReadAccess = true
                                        user.acl = acl
                                        
                                        user.signUpInBackground(block: { (success, error) in
                                            self.activityIndicator.stopAnimating()
                                            UIApplication.shared.endIgnoringInteractionEvents()
                                            
                                            if error != nil {
                                                
                                                var displayErrorMessage = "Please try again later"
                                                let error = error as NSError?
                                                if let errorMessage = error?.userInfo["error"] as? String {
                                                    displayErrorMessage = errorMessage
                                                }
                                                self.createAlert(title: "Sign Up Error", message: displayErrorMessage)
                                                
                                            } else {
                                                print("user signed up")
                                                self.performSegue(withIdentifier: "toMapView", sender: self)
                                                
                                                // save details to shortcut
                                                
                                                let entity = NSEntityDescription.insertNewObject(forEntityName: "Shortcuts", into: self.moc) as! Shortcuts
                                                entity.setValue(self.emailInput.text, forKey: "username")
                                                entity.setValue(self.passwordInput.text, forKey: "password")
                                                entity.setValue("none", forKey: "area")
                                                entity.setValue("none", forKey: "city")
                                                
                                                do {
                                                    try self.moc.save()
                                                    print("saved shortcut")
                                                } catch {
                                                    fatalError("Failure to save context: \(error)")
                                                }

                                                
                                            }
                                        })
                                    }
                                }
                            }
                        })
                    }
                }
            })
        }

    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Logged out")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toMapView") {
            if loginMode == false {
                helpClicked = false
            }
        }
    }
    
    func tap(gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: { (completed) in
                self.emailInput.resignFirstResponder()
                self.passwordInput.resignFirstResponder()
        })
    }
    
}
