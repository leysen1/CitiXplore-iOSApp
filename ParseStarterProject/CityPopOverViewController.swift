//
//  CityPopOverViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 30/01/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import CoreData
import Parse

protocol POIDataSentDelegate {
    func userSelectedData(areasChosen: [String], categoriesChosen: [String])
}

protocol RatingDataSentDelegate {
    func userSelectedData(areasChosen: [String])
}


class CityPopOverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var delegatePOI: POIDataSentDelegate? = nil
    var delegateRating: RatingDataSentDelegate? = nil
    let moc = DataController().managedObjectContext
    var baseView = ""
    var city = String()
    var titles = ["Categories","Areas"]
    var areasArray = [String]()
    var categoriesArray = [String]()
    var allArray = [[String]]()
    var areasChosen = [String]()
    var categoriesChosen = [String]()
    

    @IBOutlet weak var tableViewPopOver: UITableView!
    
    @IBAction func clearAllButton(_ sender: Any) {
        areasChosen.removeAll()
        categoriesChosen.removeAll()
        tableViewPopOver.reloadData()
    }
    
    @IBAction func submitButton(_ sender: Any) {
        if baseView == "POIView" {
            if areasChosen != [] {
                if delegatePOI != nil {
                    delegatePOI?.userSelectedData(areasChosen: areasChosen, categoriesChosen: categoriesChosen)
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                createAlert(title: "Wait!", message: "Please choose at least one area before you search")
            }
           
        } else if baseView == "RatingsView" {
            if areasChosen != [] {
                if delegateRating != nil {
                    delegateRating?.userSelectedData(areasChosen: areasChosen)
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                createAlert(title: "Wait!", message: "Please choose at least one area before you search")
            }
        }
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if baseView == "POIView" {
            self.preferredContentSize = CGSize(width: UIScreen.main.bounds.width / 1.5, height: 450)
        } else if baseView == "RatingsView" {
            self.preferredContentSize = CGSize(width: UIScreen.main.bounds.width / 1.5, height: 250)
        }
        
        print(baseView)
        
        fetchData { (Bool) in
            self.organiseData()
        }

        
    }

    func fetchData(completion: @escaping (_ result: Bool)->()) {
        
        areasArray.removeAll()
        categoriesArray.removeAll()
        allArray.removeAll()
        
        let query = PFQuery(className: "POI")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        if let areaTemp = object["area"] as? String {
                            if areaTemp != "" {
                                if self.areasArray.contains(areaTemp) == false {
                                    self.areasArray.append(areaTemp)
                                }
                            }
                        }
                        if let categoriesTemp = object["Category"] as? String {
                            if categoriesTemp != "" {
                                if self.categoriesArray.contains(categoriesTemp) == false {
                                    self.categoriesArray.append(categoriesTemp)
                                }
                            }
                        }
                        i += 1
                        if i == objects.count {
                            completion(true)
                        }
                        self.tableViewPopOver.reloadData()
                        self.tableViewPopOver.tableFooterView = UIView()
                    }
                }
            }
        }
    }
    
    func organiseData() {
        allArray.append(categoriesArray)
        allArray.append(areasArray)
    }
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
 
    func numberOfSections(in tableView: UITableView) -> Int {
        if baseView == "POIView" {
            return allArray.count
        }
        else if baseView == "RatingsView" {
            return 1
        } else {
            return 0
        }
       
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if baseView == "POIView" {
            return allArray[section].count
        }
        if baseView == "RatingsView" {
            return areasArray.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if baseView == "POIView" {
            return titles[section]
        }
        if baseView == "RatingsView" {
            return "Areas"
        } else {
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255,  green: 128/255, blue: 128/255, alpha: 1.0)
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 4, width: UIScreen.main.bounds.width, height: 20))
        titleLabel.font = UIFont(name: "Avenir Next", size: 15)
        titleLabel.textAlignment = .left
        titleLabel.textColor = .white
        if baseView == "POIView" {
            titleLabel.text = titles[section]
        } else if baseView == "RatingsView" {
            titleLabel.text = "Area"
        }
        
        view.addSubview(titleLabel)
        return view
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        cell.textLabel?.font = UIFont(name: "Avenir Next", size: 15)
        
        if baseView == "POIView" {
            cell.textLabel?.text  = allArray[indexPath.section][indexPath.row]
            if indexPath.section == 0 {
                // Categories
                if categoriesChosen.contains((cell.textLabel?.text)!) {
                   cell.accessoryType = UITableViewCellAccessoryType.checkmark
                }
            } else {
                // Areas
                if areasChosen.contains((cell.textLabel?.text)!) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                }
            }
            
        }
        else if baseView == "RatingsView" {
            cell.textLabel?.text = areasArray[indexPath.row]
            if areasChosen.contains((cell.textLabel?.text)!) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            }
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        
        if baseView == "POIView" {
            if indexPath.section == 0 {
                // Categories
                if categoriesChosen.contains(allArray[indexPath.section][indexPath.row]) {
                    cell?.accessoryType = UITableViewCellAccessoryType.none
                    categoriesChosen.remove(at: categoriesChosen.index(of: allArray[indexPath.section][indexPath.row])!)
                } else {
                    cell?.accessoryType = UITableViewCellAccessoryType.checkmark
                    categoriesChosen.append(allArray[indexPath.section][indexPath.row])
                }
            } else {
                // Areas
                if areasChosen.contains(allArray[indexPath.section][indexPath.row]) {
                    cell?.accessoryType = UITableViewCellAccessoryType.none
                    areasChosen.remove(at: areasChosen.index(of: allArray[indexPath.section][indexPath.row])!)
                } else {
                    cell?.accessoryType = UITableViewCellAccessoryType.checkmark
                    areasChosen.append(allArray[indexPath.section][indexPath.row])
                }
            }
        } else if baseView == "RatingsView" {
            if areasChosen.contains(areasArray[indexPath.row]) {
                cell?.accessoryType = UITableViewCellAccessoryType.none
                areasChosen.remove(at: areasChosen.index(of: areasArray[indexPath.row])!)
            } else {
                cell?.accessoryType = UITableViewCellAccessoryType.checkmark
                areasChosen.append(areasArray[indexPath.row])
            }
        }
 
    }
}

/*
 city = areas[indexPath.row]
 
 let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Shortcuts")
 
 do {
 let shortcutData = try moc.fetch(request) as! [Shortcuts]
 if shortcutData.count > 0 {
 // change previously saved location
 for log in shortcutData {
 if baseView == "POIView" {
 if (log.value(forKey: "area") as? String) != nil {
 let areaTemp = self.areas[indexPath.row]
 log.setValue(areaTemp, forKey: "area")
 do {
 try moc.save()
 print("updated location")
 
 if delegate != nil {
 delegate?.userSelectedData(data: areaTemp)
 self.dismiss(animated: true, completion: nil)
 }
 
 } catch { print("catch - save error") }
 }
 }
 if baseView == "RatingsView" {
 if (log.value(forKey: "area") as? String) != nil  {
 let areaTemp = self.areas[indexPath.row]
 log.setValue(areaTemp, forKey: "area")
 do {
 try moc.save()
 print("updated location")
 
 if delegate != nil {
 delegate?.userSelectedData(data: areaTemp)
 self.dismiss(animated: true, completion: nil)
 }
 
 } catch { print("catch - save error") }
 }
 }
 }
 } else {
 print("no stored shortcut found")
 }
 } catch { print("catch - fetch error") }
 */




