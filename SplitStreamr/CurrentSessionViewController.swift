//
//  CurrentSessionViewController.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class CurrentSessionViewController: UIViewController {

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        return refreshControl
    }()
    
    let manager = SessionManager.sharedInstance
    
    @IBOutlet weak var sessionTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionTableView.addSubview(refreshControl)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        self.sessionTableView.reloadData()
        refreshControl.endRefreshing()
    }
}

extension CurrentSessionViewController : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.connectedPeerCount()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = "Peer: \(manager.session.connectedPeers[indexPath.row].displayName)"
        
        return cell
    }
}

extension CurrentSessionViewController : UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}