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
    var rating = Int()
    var highscoreNames = [String]()
    var highscore = [Double]()
    
    @IBOutlet var placeName: UILabel!
    @IBOutlet var imageToRate: UIImageView!
    @IBOutlet var star1Image: UIButton!
    @IBOutlet var star2Image: UIButton!
    @IBOutlet var star3Image: UIButton!
    @IBOutlet var star4Image: UIButton!
    @IBOutlet var star5Image: UIButton!
    @IBOutlet var submitButtonLabel: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var backImage: UIImageView!
    @IBOutlet var topRatedLabel: UILabel!
    @IBOutlet var desLabel: UILabel!

    // STARS
    @IBAction func star1(_ sender: AnyObject) {
        
        if star2Image.backgroundImage(for: .normal) == UIImage(named: "star.png") {
            star2Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            star3Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            star4Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            star5Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
        } else {
            star1Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        }
        self.rating = 1
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
        self.rating = 2
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
        self.rating = 3
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
        self.rating = 4
    }
    
    @IBAction func star5(_ sender: AnyObject) {
        star1Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        star2Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        star3Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        star4Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        star5Image.setBackgroundImage(UIImage(named: "star.png"), for: .normal)
        self.rating = 5
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        star1Image.alpha = 1
        star2Image.alpha = 1
        star3Image.alpha = 1
        star4Image.alpha = 1
        star5Image.alpha = 1
        submitButtonLabel.alpha = 1
        submitButtonLabel.isEnabled = true
        backImage.image = UIImage()
        desLabel.alpha = 1
        // hide top rated
        topRatedLabel.alpha = 0
        tableView.alpha = 0
        
        updateArray { (Bool) in
            print("completed updatedArray")
            if self.nameArray.count == 0 {
                
                // self.ratingsComplete()
            }
        }
        
        
        getHighScores { (Bool) in
            self.orderHighScores()
        }
        
    
        print("username \(username)")
    }
    
    
    
    func updateArray(completion: @escaping (_ result: Bool)->()) {
        
        let query = PFQuery(className: "POI")
        query.whereKey("completed", contains: username)
        query.whereKey("rated", notContainedIn: [username])
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    if objects.count != 0 {
                        var i = 0
                        for object in objects {
                            if let imageFile = object["smallPicture"] as? PFFile {
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
                                self.ratingsComplete()
                            }
                            i += 1
                            if i == objects.count {
                                completion(true)
                            }
                        }
                    } else {
                        self.ratingsComplete()
                        completion(true)
                    }
                } else {
                    completion(true)
                    self.placeName.text = "Could not connect to the cloud"
                }
            }
        }
    }
    
    func ratingsComplete() {
        self.placeName.text = "You have rated all your sightings!"
        self.imageToRate.image = UIImage()
        self.star1Image.alpha = 0
        self.star2Image.alpha = 0
        self.star3Image.alpha = 0
        self.star4Image.alpha = 0
        self.star5Image.alpha = 0
        self.submitButtonLabel.alpha = 0
        self.submitButtonLabel.isEnabled = false
        self.backImage.image = UIImage(named: "KandC.jpg")
        
        
        // show Top Rated
        self.topRatedLabel.alpha = 1
        self.tableView.alpha = 1
        self.desLabel.alpha = 0

    }

    
    
    func saveSubmit() {
        
        if self.rating != 0 {
            if nameArray.count > 0 {
                let query2 = PFQuery(className: "POI")
                query2.whereKey("name", equalTo: self.nameArray[0])
                query2.findObjectsInBackground(block: { (objects, error) in
                    if error != nil {
                        print("error")
                    } else {
                        if let objects = objects {
                            for object in objects {
                                object.add(self.rating, forKey: "rating")
                                object.add(self.username, forKey: "rated")
                                object.saveInBackground(block: { (success, error) in
                                    if error != nil {
                                        print("error")
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
        } else {
            // no rating given
            
        }
    }
    
    
    @IBAction func submit(_ sender: AnyObject) {
        
        if username != "" {
            saveSubmit()
        }
        
    }

    func newImage() {
        
        if nameArray.count > 0 {
            self.rating = 0
            nameArray.remove(at: 0)
            imageArray.remove(at: 0)
            if nameArray.count > 0 {
                placeName.text = nameArray[0]
                imageToRate.image = imageArray[0]
                star1Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
                star2Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
                star3Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
                star4Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
                star5Image.setBackgroundImage(UIImage(named: "greystar.png"), for: .normal)
            
            } else {
                self.ratingsComplete()
            }
        } else {
            self.ratingsComplete()
        }
    }
    
    func getHighScores(completion: @escaping (_ result: Bool)->()) {
        let query = PFQuery(className: "POI")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        
                        if let tempRatingArray = object["rating"] as? [Int] {
                            if let tempName = object["name"] as? String {
                                self.highscoreNames.append(tempName)
                            }
                            var sumOfRatings = 0
                            var numberOfRatings = 0
                            for item in tempRatingArray {
                                sumOfRatings = item + sumOfRatings
                                numberOfRatings += 1
                            }
                            let tempHighScore = round((Double(sumOfRatings) / Double(numberOfRatings)) * 100) / 100
                            
                            self.highscore.append(tempHighScore)
                        }
                        i += 1
                        if i == objects.count {
                            completion(true)
                        }
                    }
                    print("highscore name \(self.highscoreNames)")
                    print("highscores \(self.highscore)")
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func orderHighScores() {
        
        var dictName: [String: Double] = [:]
        
        for (name, number) in self.highscoreNames.enumerated() {
            dictName[number] = self.highscore[name]
        }
        let sortedName = (dictName as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
        self.highscoreNames = sortedName as! [String]
        
        self.highscore.sort()
        
        self.highscoreNames.reverse()
        self.highscore.reverse()
        
        print("sorted")
        print("highscore name \(self.highscoreNames)")
        print("highscores \(self.highscore)")
        
        tableView.reloadData()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return highscoreNames.count
    }
    

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FavTableViewCell
        cell.nameLabel.text = highscoreNames[indexPath.row]
        cell.starRating.text = String(highscore[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        ratedPOI = highscoreNames[indexPath.row]
        self.navigationController?.popToRootViewController(animated: true)
        
    }
    

  }
