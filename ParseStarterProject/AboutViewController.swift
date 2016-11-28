//
//  AboutViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 28/11/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBAction func close(_ sender: AnyObject) {
        self.removeAnimate()
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showAnimate()
        // Do any additional setup after loading the view.
    }
    
    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.3,y: 1.3)
        self.view.alpha = 0
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1
            self.view.transform = CGAffineTransform(scaleX: 1.0,y: 1.0)
        })
    }
    
    func removeAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0
        }, completion:{(finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
