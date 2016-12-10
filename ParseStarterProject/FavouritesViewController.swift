//
//  FavouritesViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 29/11/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse

class FavouritesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var username = ""
    var imageArray = [UIImage]()
    var nameArray = [String]()
    var rating = ""
    var highscoreNames = [String]()
    var highscore = [Double]()
    
    @IBOutlet var placeName: UILabel!
    @IBOutlet var imageToRate: UIImageView!
    @IBOutlet var star1Image: UIButton!
    @IBOutlet var star2Image: UIButton!
    @IBOutlet var star3Image: UIButton!
    @IBOutlet var star4Image: UIButton!
    @IBOutlet var star5Image: UIButton!


    @IBAction func star1(_ sender: AnyObject) {
        
        if star2Image.backgroundImage(for: .normal) == UIImage(named: "star.png") {
            star2Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            star3Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            star4Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            star5Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        } else {
            star1Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        }
        self.rating = "onestar"
    }
    @IBAction func star2(_ sender: AnyObject) {
        
        if star3Image.backgroundImage(for: .normal) == UIImage(named: "star.png") {
            star3Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            star4Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            star5Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        } else {
            star1Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
            star2Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        }
        self.rating = "twostar"
    }

    @IBAction func star3(_ sender: AnyObject) {
        if star4Image.backgroundImage(for: .normal) == UIImage(named: "star.png") {
            star4Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            star5Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        } else {
            star1Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
            star2Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
            star3Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        }
        self.rating = "threestar"
    }
    
    @IBAction func star4(_ sender: AnyObject) {
        if star5Image.backgroundImage(for: .normal) == UIImage(named: "star.png") {
            star5Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        } else {
            star1Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
            star2Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
            star3Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
            star4Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        }
        self.rating = "fourstar"
    }
    
    @IBAction func star5(_ sender: AnyObject) {
        star1Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        star2Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        star3Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        star4Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        star5Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        self.rating = "fivestar"
    }
    
    func saveSubmit() {
        
        if nameArray.count > 0 {
            let query2 = PFQuery(className: "POI")
            query2.whereKey("name", equalTo: self.nameArray[0])
            query2.findObjectsInBackground(block: { (objects, error) in
                if error != nil {
                    print(error)
                } else {
                    if let objects = objects {
                        for object in objects {
                            object.add(self.username, forKey: self.rating)
                            object.saveInBackground(block: { (success, error) in
                                if error != nil {
                                    print(error)
                                } else {
                                    // do somthing
                                    print("saved")
                                    self.newImage()
                                    
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    
    
    @IBAction func submit(_ sender: AnyObject) {
        
        if username != "" {
            if self.rating != "" {
                saveSubmit()
            } else {
                print("no rating given")
            }
        }
        
    }
    
    @IBOutlet var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateArray()
        
        getHighScores()
        
        print("username \(username)")
    }
    
    
    
    func updateArray() {
        
        let query = PFQuery(className: "POI")
        query.whereKey("completed", contains: username)
        query.whereKey("fivestar", notContainedIn: [username])
        query.whereKey("fourstar", notContainedIn: [username])
        query.whereKey("threestar", notContainedIn: [username])
        query.whereKey("twostar", notContainedIn: [username])
        query.whereKey("onestar", notContainedIn: [username])
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
            } else {
                if let objects = objects {
                    for object in objects {
                        if let imageFile = object["picture"] as? PFFile {
                            imageFile.getDataInBackground(block: { (data, error) in
                                if let imageData = data {
                                    self.imageArray.append(UIImage(data: imageData)!)
                                    if self.imageArray.count == 1 {
                                        self.imageToRate.image = self.imageArray[0]
                                    }
                                }
                                if let poiName = object["name"] as? String {
                                    self.nameArray.append(poiName)
                                    if self.nameArray.count == 1 {
                                        self.placeName.text = self.nameArray[0]
                                    }
                                    print("namearray \(self.nameArray)")
                                }
                                
                            })
                            
                        } else {
                            // no image in object
                            print("could not get image")
                        }
                    }

                }
            }
        }
    }
    
    
    func newImage() {
        nameArray.remove(at: 0)
        imageArray.remove(at: 0)
        
        if nameArray.count > 0 {
            placeName.text = nameArray[0]
            imageToRate.image = imageArray[0]
        } else {
            placeName.text = "You have rated all your sightings!"
            imageToRate.image = UIImage()
        }
        
        star1Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        star2Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        star3Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        star4Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        star5Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        

    }
    
    func getHighScores() {
        let query = PFQuery(className: "POI")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error)
            } else {
                if let objects = objects {
                    for object in objects {
                        if let tempName = object["name"] as? String {
                            self.highscoreNames.append(tempName)
                        }
                        var score = 0
                        var numberOfRatings = 0
                        if let fiveArray = object["fivestar"] as? NSArray {
                            score += (fiveArray.count * 5)
                            numberOfRatings += fiveArray.count
                        }
                        if let fourArray = object["fivestar"] as? NSArray {
                            score += (fourArray.count * 4)
                            numberOfRatings += fourArray.count
                        }
                        if let threeArray = object["fivestar"] as? NSArray {
                            score += (threeArray.count * 3)
                            numberOfRatings += threeArray.count
                        }
                        if let twoArray = object["fivestar"] as? NSArray {
                            score += (twoArray.count * 2)
                            numberOfRatings += twoArray.count
                        }
                        if let oneArray = object["fivestar"] as? NSArray {
                            score += oneArray.count
                            numberOfRatings += oneArray.count
                        }
                        if numberOfRatings > 0 {
                            let tempHighscore = round(Double((score / numberOfRatings) * 10)) / 10
                            self.highscore.append(tempHighscore)
                        
                        } else {
                            self.highscore.append(0)
                        }
                        print("highscore \(self.highscore)")
                        print("highscorename \(self.highscoreNames)")
                        
                    }
                }
            }
        }
        
    }

    @IBAction func button(_ sender: AnyObject) {
        print("highscore \(self.highscore)")
        print("highscorename \(self.highscoreNames)")
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FavTableViewCell
        
        
        return cell
    }
    
    

    

  }
