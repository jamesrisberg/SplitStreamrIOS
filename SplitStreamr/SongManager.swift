//
//  SongManager.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation

class SongManager: NSObject {
    
    static let sharedInstance : SongManager = SongManager();
    
    var songs: Array<Song> = [];
    var songURLs: Dictionary<String, String> {
        get {
            if let tempSongUrls = NSUserDefaults.standardUserDefaults().dictionaryForKey(savedSongsDictionaryKey) {
                // TODO: NOT SAFE!!
                return tempSongUrls as! Dictionary<String, String>;
            }
            else {
                return Dictionary<String, String>();
            }
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: savedSongsDictionaryKey);
        }
    }
    
    var currentlyDownloadingSongId : String?;
    var shouldPlayWhenDownloaded : Bool = false;
    
    var didDownloadSongs : Bool = false;
    var onSongsFinishedDownloading : (() -> Void)?;
    
    var onSongReadyToPlay : ((songUrl : String) -> Void)?;
    
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
    
    func songDownloaded(note: NSNotification) {
        // TODO: Everything here is very unsafe
        var songInfo = note.userInfo;
        let songId = songInfo!["songId"] as! String;
        let songURL = songInfo!["songURL"] as! String;
        let index = songs.indexOf({$0.id == songId});
        
        var song = songs[index!];
        song.url = songURL;
        songs[index!] = song;
        songURLs[songId] = songURL;
        
        if (self.shouldPlayWhenDownloaded) {
            if (self.currentlyDownloadingSongId == songId) {
                self.currentlyDownloadingSongId = nil;
                self.shouldPlayWhenDownloaded = false;
                playSong(songURL);
            }
        }
        
        self.currentlyDownloadingSongId = nil;
    }
    
    func playSongWhenReady(songId : String) {
        if let songURL = songURLs[songId] {
            playSong(songURL);
        }
        else {
            self.shouldPlayWhenDownloaded = true;
            downloadSong(songId);
        }
    }
    
    func preDownloadSong(songId : String) {
        if let _ = currentlyDownloadingSongId {
            return;
        }
        else {
            downloadSong(songId);
        }
    }
    
    func playSong(songURL: String) {
        onSongReadyToPlay?(songUrl: songURL);
    }

    private func downloadSong(songId : String) {
        if let song = getSongForId(songId) {
            self.currentlyDownloadingSongId = songId;
            SessionManager.sharedInstance.streamSong(song);
        }
    }
    
    private func getSongForId(songId : String) -> Song? {
        let index = songs.indexOf({$0.id == songId});
        
        if (index > 0) {
            return songs[index!];
        }
        return nil;
    }
}
