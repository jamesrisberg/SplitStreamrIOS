//
//  SongTableView.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class SongTableView: UITableView {
    var currentPlayerIndex : Int = 0;
    
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
    
    func playNextSong() {
        if (currentPlayerIndex == SongManager.sharedInstance.songs.count - 1) {
            currentPlayerIndex = 0;
        }
        else {
            currentPlayerIndex += 1;
        }
        
        playSongAtIndex(currentPlayerIndex);
    }
    
    func playPreviousSong() {
        if (currentPlayerIndex == 0) {
            currentPlayerIndex = SongManager.sharedInstance.songs.count - 1;
        }
        else {
            currentPlayerIndex -= 1;
        }
        
        playSongAtIndex(currentPlayerIndex);
    }
    
    func playSongAtIndex(index: Int) {
        let song = SongManager.sharedInstance.songs[index];
        SongManager.sharedInstance.playSongWhenReady(song.id);
    }
}

extension SongTableView : UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let song = SongManager.sharedInstance.songs[indexPath.row];
        SongManager.sharedInstance.playSongWhenReady(song.id);
        self.currentPlayerIndex = indexPath.row;
        self.deselectRowAtIndexPath(indexPath, animated: true);
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
        let cell = tableView.dequeueReusableCellWithIdentifier("songCell") as! SongCell;
        
        let song = SongManager.sharedInstance.songs[indexPath.row];
        
        cell.titleArtistLabel?.text = "\(song.name) - \(song.artist)";
        
        return cell;
    }
}