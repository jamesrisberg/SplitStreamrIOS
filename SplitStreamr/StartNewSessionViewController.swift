//
//  StartNewSessionViewController.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class StartNewSessionViewController: UIViewController {
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged);
        
        return refreshControl;
    }()
    
    let manager = SessionManager.sharedInstance;
    
    @IBOutlet weak var peerTableView: UITableView!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        peerTableView.addSubview(refreshControl);
        
        NSNotificationCenter.defaultCenter().addObserverForName("PeersUpdated", object: nil, queue: nil, usingBlock: peersUpdated);
        
        manager.startBrowsing();
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }

    func handleRefresh(refreshControl: UIRefreshControl) {
        self.peerTableView.reloadData();
        refreshControl.endRefreshing();
    }
    
    func peersUpdated(notification: NSNotification) {
        self.peerTableView.reloadData();
    }
}

extension StartNewSessionViewController : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.peerCount();
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell();
        
        cell.textLabel?.text = "Peer: " + manager.peerNameAtIndex(indexPath.row).displayName;
        
        if manager.session.connectedPeers.contains(manager.peerNameAtIndex(indexPath.row)) {
            cell.backgroundColor = UIColor.redColor();
            cell.userInteractionEnabled = false;
        }
        
        return cell;
    }
}

extension StartNewSessionViewController : UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        manager.invitePeerAtIndex(indexPath.row);
    }
}
