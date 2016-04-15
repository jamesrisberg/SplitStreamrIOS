//
//  MenuViewController.swift
//  SplitStreamr
//
//  Created by James on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    var accountDrawer: AccountView?;
    var drawerUp = false;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        accountDrawer = AccountView.instanceFromNib()
        var frame = self.view.frame
        frame.origin.y = (frame.size.height - 60)
        accountDrawer?.frame = frame
        accountDrawer?.bounds = self.view.bounds
        if let view = accountDrawer {
            self.view.addSubview(view)
        }
        
        accountDrawer?.usernameLabel.text = "Account";
        
        accountDrawer?.settingsButton.addTarget(self, action: #selector(MenuViewController.toggleAccountDrawer), forControlEvents: .TouchUpInside)
        accountDrawer?.logoutButton.addTarget(self, action: #selector(MenuViewController.logout), forControlEvents: .TouchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
    }
    
    func logout() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func toggleAccountDrawer() {
        if drawerUp {
            drawerUp = false
            lowerDrawer()
        } else {
            drawerUp = true
            raiseDrawer()
        }
    }
    
    func raiseDrawer() {
        UIView.animateWithDuration(0.5) {
            var frame = self.view.frame
            frame.origin.y = 20
            self.accountDrawer?.frame = frame
        }
    }
    
    func lowerDrawer() {
        UIView.animateWithDuration(0.5) {
            var frame = self.view.frame
            frame.origin.y = (frame.size.height - 60)
            self.accountDrawer?.frame = frame
        }
    }
}

