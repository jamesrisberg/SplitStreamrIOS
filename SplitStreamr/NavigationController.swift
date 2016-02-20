//
//  NavigationController.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 Joseph Pecoraro. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController, UIViewControllerTransitioningDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.barTintColor = navigationBarColor;
        self.navigationBar.tintColor = offWhiteColor;
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : offWhiteColor];
    }
}