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
    @IBOutlet weak var downloadedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        NSNotificationCenter.defaultCenter().addObserverForName("InvitationAccepted", object: nil, queue: nil, usingBlock: invitationAccepted);
        NSNotificationCenter.defaultCenter().addObserverForName("DownloadedSoFar", object: nil, queue: nil, usingBlock: updateData);
        
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
    
    func updateData(notification: NSNotification) {
        if let dataCount = notification.userInfo!["soFar"] {
            let kilobytes: Int = Int(dataCount as! NSNumber)/1024;
            self.downloadedLabel.text = "\(kilobytes) Kb";
        }
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
