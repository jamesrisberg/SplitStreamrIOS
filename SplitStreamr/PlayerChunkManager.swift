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
    var currentSongData: NSMutableData = NSMutableData();
    var currentSongChunkCount: Int = 0;
    
    override init() {
        super.init();
    }
    
    func prepareForSong(song: Song) {
        currentSongChunkCount = song.numberOfChunks;
        recievedChunks = [NSData?](count: currentSongChunkCount, repeatedValue: nil);
    }
    
    func addNodeChunk(chunkNumber: Int, musicData: NSData) {
        recievedChunks[chunkNumber] = musicData;
        
        if recievedChunks.count == currentSongChunkCount {
            songFinished()
        }
    }
    
    func songFinished() {
        for index in 0..<recievedChunks.count {
            if let data = recievedChunks[index] {
                currentSongData.appendData(data);
            }
        }
        
        
    }
}

extension PlayerChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(chunkNumber: Int, musicData: NSData) {
        recievedChunks[chunkNumber] = musicData;
        if recievedChunks.count == currentSongChunkCount {
            songFinished()
        }
    }
    
    func sessionIdReceived(sessionId: String) {
        self.sessionId = sessionId;
        print(sessionId);
        SessionManager.sharedInstance.setSessionId(sessionId);
    }
    
    func errorRecieved(error: NSError) {
        print(error.debugDescription);
    }
    
    func didEstablishConnection() {
        SessionManager.sharedInstance.createNewSession();
    }
}