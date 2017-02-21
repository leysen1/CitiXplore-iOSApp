//
//  ExploreFilterViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 12/02/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse

class ExploreFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var city = "London"
    var areasArray = [String]()
    var imagesArray = [PFFile]()
    var chosenArea = String()
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        navigationController?.navigationBar.barTintColor = UIColor(red: 89/255,  green: 231/255, blue: 185/255, alpha: 1.0)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20)]
        navigationController?.navigationBar.isTranslucent = false
        
        
        
        
        fetchData { (Bool) in
            self.tableView.reloadData()
            self.tableView.tableFooterView = UIView()
        }
    }
    
    func fetchData(completion: @escaping (_ result: Bool)->()) {
        let query = PFQuery(className: "Area")
        query.whereKey("city", equalTo: city)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        if let areaTemp = object["name"] as? String {
                            if areaTemp != "" {
                                if self.areasArray.contains(areaTemp) == false {
                                    self.areasArray.append(areaTemp)
                                }
                            }
                        }
                        if let imageTemp = object["picture"] as? PFFile {
                            self.imagesArray.append(imageTemp)
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


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return areasArray.count
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ExploreFilterTableViewCell
        cell.nameLabel.text = areasArray[indexPath.row]
        cell.backgroundColor = UIColor.clear
        
        if imagesArray != [] {
            imagesArray[indexPath.row].getDataInBackground(block: { (data, error) in
                if let imageData = data {
                    if let downloadedImage = UIImage(data: imageData) {
                        cell.backgroundImage.image = downloadedImage
                    }
                }
            })
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenArea = areasArray[indexPath.row]
        performSegue(withIdentifier: "exploreSegue", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "exploreSegue") {
            let POISVC = segue.destination as? POIsViewController
            POISVC?.areasChosenMain = [chosenArea]
            
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            
        }
    }
    
}
