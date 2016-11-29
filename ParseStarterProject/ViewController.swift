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

class ViewController: UIViewController {

    @IBOutlet var usernameInput: UITextField!
    @IBOutlet var passwordInput: UITextField!
    @IBOutlet var changeModeLabel: UILabel!
    @IBOutlet var loginOrSignupButtonLabel: UIButton!    
    @IBOutlet var changeSignupOrLoginButtonLabel: UIButton!
    
    var loginMode = true
    var activityIndicator = UIActivityIndicatorView()
    
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
        
        if loginMode == true {
            // log in user
            
            PFUser.logInWithUsername(inBackground: usernameInput.text!, password: passwordInput.text!, block: { (user, error) in
                
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
                    // self.performSegue(withIdentifier: "toMapView", sender: self)
                    self.performSegue(withIdentifier: "toTransition", sender: self)
                    
                    
                }
            })

        } else if loginMode == false {
            // sign up user
            
            let user = PFUser()
            user.username = usernameInput.text
            user.password = passwordInput.text
            
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
                    
                    
                    // self.performSegue(withIdentifier: "mapSegue", sender: self)
                    
                }
            })
            
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
        
        // rid keyboard
        let dismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(tap))
        view.addGestureRecognizer(dismissKeyboard)
        
    }
    
    
    func tap(gesture: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: { (completed) in
                self.usernameInput.resignFirstResponder()
                self.passwordInput.resignFirstResponder()
        })
    }
    
}
