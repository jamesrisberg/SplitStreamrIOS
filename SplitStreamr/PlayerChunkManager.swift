//
//  PlayerChunkManager.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation

class PlayerChunkManager: NSObject {
    
    var sessionId: String?;
    
    var recievedChunks: [NSData?] = [];
    var chunksRecieved = 0;
    var currentSongData: NSMutableData = NSMutableData();
    var currentSongChunkCount: Int = 0;
    var currentSong: Song!;
    
    override init() {
        super.init();
    }
    
    func prepareForSong(song: Song) {
        currentSong = song;
        currentSongChunkCount = song.numberOfChunks;
        recievedChunks = [NSData?](count: currentSongChunkCount, repeatedValue: nil);
    }
    
    func addNodeChunk(chunkNumber: Int, musicData: NSData) {
        recievedChunks[chunkNumber] = musicData;
        chunksRecieved += 1;
        
        if chunksRecieved == currentSongChunkCount {
            songFinished()
        }
    }
    
    func songFinished() {
        for index in 0..<recievedChunks.count {
            if let data = recievedChunks[index] {
                currentSongData.appendData(data);
            }
        }
        
        SongManager.sharedInstance.songDownloaded(currentSong, data: currentSongData);
    }
}

extension PlayerChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData) {
        recievedChunks[chunkNumber] = musicData;
        chunksRecieved += 1;
        if chunksRecieved == currentSongChunkCount {
            songFinished()
        }
    }
    
    func didFinishReceivingSong(songId: String) {
        
    }
    
    func sessionIdReceived(sessionId: String) {
        self.sessionId = sessionId;
        SessionManager.sharedInstance.setSessionId(sessionId);
    }
    
    func errorRecieved(error: NSError) {
        print(error.debugDescription);
    }
    
    func didEstablishConnection() {
        SessionManager.sharedInstance.createNewSession();
    }
}