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
        
        if User.sharedInstance.isGuest {
            accountDrawer?.logoutButton.setTitle("Login", forState: .Normal)
        }
        
        accountDrawer?.settingsButton.addTarget(self, action: #selector(MenuViewController.toggleAccountDrawer), forControlEvents: .TouchUpInside)
        accountDrawer?.logoutCallback = logout;
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
    
    @IBAction func musicPlayerPressed(sender: AnyObject) {
        if User.sharedInstance.isGuest {
            // Show error alert
            let alertController = UIAlertController(title: "Please Sign In", message: "You must be signed in to access the music player", preferredStyle: .Alert)
            let signInAction = UIAlertAction(title: "Sign In", style: .Default, handler: { (_) in
                self.logout()
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            alertController.addAction(signInAction)
            presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            self.performSegueWithIdentifier("menutomusicplayer", sender: self)
        }
    }
}

