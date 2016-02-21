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
    
    override init() {
        super.init();
        self.downloadSongs();
        self.registerToReceiveNewSongDownloadNotification();
    }
    
    func registerToReceiveNewSongDownloadNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "songDownloaded:", name: songDownloadedNotificationIdentifier, object: nil);
    }
    
    func downloadSongs() {
        NetworkFacade().getSongs({ (error, list) -> Void in
            if error != nil {
                print(error.debugDescription);
            } else {
                if let songs = list {
                    self.songs = songs;
                    self.didDownloadSongs = true;
                    self.onSongsFinishedDownloading?();
                }
            }
        });
    }
    
    func songDownloaded(song: Song, data: NSData) {        
        if (self.shouldPlayWhenDownloaded) {
            if (self.currentlyDownloadingSongId == song.id) {
                self.currentlyDownloadingSongId = nil;
                self.shouldPlayWhenDownloaded = false;
                playSong(song, data: data);
            }
        }
        
        self.currentlyDownloadingSongId = nil;
    }
    
    func playSongWhenReady(songId : String) {
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
    
    func playSong(song: Song, data: NSData) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.onSongReadyToPlay?(song: song, data: data);
        });
    }

    private func downloadSong(songId : String) {
        if let song = getSongForId(songId) {
            self.currentlyDownloadingSongId = songId;
            SessionManager.sharedInstance.streamSong(song);
        }
    }
    
    private func getSongForId(songId : String) -> Song? {
        let index = songs.indexOf({$0.id == songId});
        
        if (index >= 0) {
            return songs[index!];
        }
        return nil;
    }
}
