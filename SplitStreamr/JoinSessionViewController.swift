//
//  JoinSessionViewController.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit
import SVProgressHUD

class JoinSessionViewController: UIViewController {
    
    let manager = SessionManager.sharedInstance
    
    @IBOutlet weak var waitingLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        NSNotificationCenter.defaultCenter().addObserverForName("InvitationAccepted", object: nil, queue: nil, usingBlock: invitationAccepted);
        NSNotificationCenter.defaultCenter().addObserverForName("DidDisconnectFromSession", object: nil, queue: nil, usingBlock: didDisconnect);
        
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
    
    func didDisconnect(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), { ()->Void in
            self.activityIndicator.startAnimating();
            self.manager.startAdvertising();
            self.waitingLabel.text = "You were disconnected! Waiting to be invited to a new session.";
        });
    }
    
    func downloadingFile() {
        SVProgressHUD.show()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // time-consuming task
            dispatch_async(dispatch_get_main_queue(), {
                SVProgressHUD.dismiss();
                });
            });
    }
    
    @IBAction func backToMenu() {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}
