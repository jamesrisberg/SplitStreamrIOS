//
//  SongManager.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import SVProgressHUD

class SongManager: NSObject {
    
    static let sharedInstance : SongManager = SongManager();
    
    var songs: Array<Song> = [];
    
    var currentlyDownloadingSongId : String?;
    var shouldPlayWhenDownloaded : Bool = false;
    
    var didDownloadSongs : Bool = false;
    var onSongsFinishedDownloading : (() -> Void)?;
    
    var onSongReadyToPlay : ((song : Song, data: NSData) -> Void)?;
    var queueChunkToPlay : ((chunkNumber: Int, data: NSData) -> Void)?;
    
    override init() {
        super.init();
        self.registerToReceiveNewSongDownloadNotification();
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    func registerToReceiveNewSongDownloadNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SongManager.songDownloaded), name: songDownloadedNotificationIdentifier, object: nil);
    }
    
    func downloadSongs() {
        NetworkFacade().getSongs({ (error, list) -> Void in
            if error != nil {
                debugLog(error.debugDescription);
            } else {
                if let songs = list {
                    self.songs = songs;
                    self.didDownloadSongs = true;
                    self.onSongsFinishedDownloading?();
                }
            }
        });
    }
    
    func songDownloaded() {
        self.currentlyDownloadingSongId = nil;
    }
    
    func queueChunk(chunkNumber: Int, data: NSData) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.queueChunkToPlay?(chunkNumber: chunkNumber, data: data);
        });
    }
    
    func playSongWhenReady(songId : String) {
        let song = getSongForId(songId)
        NSNotificationCenter.defaultCenter().postNotificationName("SongSelected", object: nil, userInfo: ["songName" : song!.name, "songArtist" : song!.artist, "songLength" : "\(song!.length)"]);
        self.shouldPlayWhenDownloaded = true;
        downloadSong(songId);
    }
    
    func preDownloadSong(songId : String) {
        if let _ = currentlyDownloadingSongId {
            return;
        }
        else {
            downloadSong(songId);
        }
    }

    private func downloadSong(songId : String) {
        if let song = getSongForId(songId) {
            self.currentlyDownloadingSongId = songId;
            SessionManager.sharedInstance.streamSong(song);
        }
    }
    
    func getSongForId(songId : String) -> Song? {
        let index = songs.indexOf({$0.id == songId});
        
        if (index >= 0) {
            return songs[index!];
        }
        return nil;
    }
}
