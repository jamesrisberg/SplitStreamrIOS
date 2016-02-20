//
//  JoinSessionViewController.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class JoinSessionViewController: UIViewController {
    
    let manager = SessionManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.startAdvertising()
    }
}
