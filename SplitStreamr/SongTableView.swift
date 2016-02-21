//
//  SongTableView.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class SongTableView: UITableView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        
        delegate = self;
        dataSource = self;
        
        if !SongManager.sharedInstance.didDownloadSongs {
            SongManager.sharedInstance.onSongsFinishedDownloading = {
                self.reloadData();
            }
        }
    }
}

extension SongTableView : UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let song = SongManager.sharedInstance.songs[indexPath.row];
        SongManager.sharedInstance.playSongWhenReady(song.id);
    }
}

extension SongTableView : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SongManager.sharedInstance.songs.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell();
        
        cell.textLabel?.text = "\(SongManager.sharedInstance.songs[indexPath.row].name) - \(SongManager.sharedInstance.songs[indexPath.row].artist)";
        
        return cell;
    }
}