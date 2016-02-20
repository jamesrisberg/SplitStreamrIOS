//
//  SongTableView.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class SongTableView: UITableView {
    
    var songs: Array<Song> = [];
    
    func getSongs() {
        delegate = self;
        dataSource = self;
        
        NetworkFacade().getSongs({ (error, list) -> Void in
            if error != nil {
                print(error.debugDescription);
            } else {
                if let songs = list {
                    self.songs = songs;
                    self.reloadData()
                }
            }
        });
    }
}

extension SongTableView : UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}

extension SongTableView : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell();
        
        cell.textLabel?.text = "\(songs[indexPath.row].name) - \(songs[indexPath.row].artist)";
        
        return cell;
    }
}