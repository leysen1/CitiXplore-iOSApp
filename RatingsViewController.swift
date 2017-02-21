//
//  RatingsViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 30/01/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse
import CoreData


protocol ratedPOIDelegate {
    func getChosenPOI(ratedPOI: String)
}


class RatingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate, RatingDataSentDelegate {
    
    let moc = DataController().managedObjectContext
    let rankings = ["Must See","When in the Area","Worth a detour","Point of Interest"]
    var rating1 = [String]()
    var rating2 = [String]()
    var rating3 = [String]()
    var rating4 = [String]()
    var data = [[String]]()
    var city = "London"
    var chosenArea = [String]()
    var completedArray = [String]()
    
    // Stars
    let starone = UIImageView(frame: CGRect(x: 10, y: 4, width: 20, height: 20))
    let staroneImage = UIImage(named: "star.png")!
    let startwo = UIImageView(frame: CGRect(x: 10, y: 4, width: 45, height: 20))
    let startwoImage = UIImage(named: "2star.png")!
    let starthree = UIImageView(frame: CGRect(x: 10, y: 4, width: 65, height: 20))
    let starthreeImage = UIImage(named: "3star.png")!
    let starfour = UIImageView(frame: CGRect(x: 10, y: 4, width: 85, height: 20))
    let starfourImage = UIImage(named: "4star.png")!
    var starArray = [UIImageView]()

    @IBOutlet weak var navBarBox: UINavigationBar!
    @IBOutlet weak var RatingsTitle: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        self.navigationController?.title = "Ratings"
        self.tableView.tableFooterView = UIView()
        
        starone.image = staroneImage
        startwo.image = startwoImage
        starthree.image = starthreeImage
        starfour.image = starfourImage
        starArray = [starfour, starthree, startwo, starone]
        
        fetchAreaData { (Bool) in
            self.fetchData { (Bool) in
                self.orderData()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        
        // Aesthetics
        RatingsTitle.title = "Ratings"
        navBarBox.titleTextAttributes = [NSFontAttributeName : UIFont(name: "AvenirNext-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20), NSForegroundColorAttributeName: UIColor(red: 23, green: 31, blue: 149, alpha: 1)]
        view.backgroundColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        navBarBox.barTintColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
    }
    
    // Functions 
    
    func fetchAreaData(completion: @escaping (_ result: Bool)->()) {
        let query = PFQuery(className: "POI")
        query.whereKey("city", equalTo: city)
        query.findObjectsInBackground { (objects, error) in
            if let objects = objects {
                var i = 0
                for object in objects {
                    if let tempArea = object["area"] as? String {
                        if tempArea != "" {
                            if self.chosenArea.contains(tempArea) == false {
                                self.chosenArea.append(tempArea)
                            }
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

    func fetchData(completion: @escaping (_ result: Bool)->()) {
        
        rating1.removeAll()
        rating2.removeAll()
        rating3.removeAll()
        rating4.removeAll()
        
        let query = PFQuery(className: "POI")
        query.whereKey("city", equalTo: city)
        if chosenArea != [] {
            query.whereKey("area", containedIn: chosenArea)
        }
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        if let tempName = object["name"] as? String {
                            if let tempRating = object["ratings"] as? Int {
                                
                                switch tempRating {
                                case 1:
                                    self.rating1.append(tempName)
                                case 2:
                                    self.rating2.append(tempName)
                                case 3:
                                    self.rating3.append(tempName)
                                case 4:
                                    self.rating4.append(tempName)
                                default:
                                    break
                                }
                            }
                        }
                        i += 1
                        if objects.count == i {
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    func orderData() {
        
        data.removeAll()
        
        rating1.sort()
        rating2.sort()
        rating3.sort()
        rating4.sort()
        
        data.append(self.rating4)
        data.append(self.rating3)
        data.append(self.rating2)
        data.append(self.rating1)
        
        print("all in one")
        print(data)
        
        tableView.reloadData()
    }
    

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func userSelectedData(areasChosen: [String]) {
        chosenArea = areasChosen
        print(chosenArea)
        fetchData { (Bool) in
            self.orderData()
        }
    }

    
    // Table

    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count   }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count  }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return rankings[section]    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(red: 80/255,  green: 148/255, blue: 230/255, alpha: 1.0)

        let titleLabel = UILabel(frame: CGRect(x: 0, y: 4, width: UIScreen.main.bounds.width, height: 20))
        titleLabel.text = self.rankings[section]
        titleLabel.font = UIFont(name: "Avenir Next", size: 20)
        
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        view.addSubview(starArray[section])

        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        cell.textLabel?.text = data[indexPath.section][indexPath.row]
        cell.textLabel?.font = UIFont(name: "Avenir Next", size: 17)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ratedPOI = data[indexPath.section][indexPath.row]
        tabBarController?.selectedIndex = 0
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "cityPopover" {
            let popoverVC: CityPopOverViewController = segue.destination as! CityPopOverViewController
            popoverVC.baseView = "RatingsView"
            popoverVC.delegateRating = self
            popoverVC.areasChosen = chosenArea
            
            popoverVC.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverVC.popoverPresentationController!.delegate = self
            popoverVC.preferredContentSize = CGSize(width: UIScreen.main.bounds.width / 1.5, height: 150)
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}




