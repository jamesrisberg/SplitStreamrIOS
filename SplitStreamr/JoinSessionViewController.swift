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
    
    @IBOutlet weak var waitingLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        NSNotificationCenter.defaultCenter().addObserverForName("InvitationAccepted", object: nil, queue: nil, usingBlock: invitationAccepted);
        
        manager.startAdvertising();
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
        
        NSNotificationCenter.defaultCenter().removeObserver(self);
        
        manager.stopAdvertising();
        manager.disconnectFromSession();
    }

    func invitationAccepted(notification: NSNotification) {
        self.activityIndicator.stopAnimating();
        manager.stopAdvertising();
        self.waitingLabel.text = "You are part of the session! Leaving this screen will disconnect your device.";
    }
}
