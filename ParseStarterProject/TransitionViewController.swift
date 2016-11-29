//
//  TransitionViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 29/11/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit

class TransitionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(timeToMoveOn), userInfo: nil, repeats: false)
        
    }

    func timeToMoveOn() {
        self.performSegue(withIdentifier: "toMap", sender: self)
    }

}
