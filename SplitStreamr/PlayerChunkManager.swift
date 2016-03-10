//
//  PlayerChunkManager.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class PlayerChunkManager: NSObject {
    
    var sessionId: String?;
    
    var recievedChunks: [NSData?] = [];
    var chunksRecieved = 0;
    var currentSongData: NSMutableData = NSMutableData();
    var currentSongChunkCount: Int = 0;
    var currentSong: Song?;
    
    override init() {
        super.init();
    }
    
    func prepareForSong(song: Song) {
        chunksRecieved = 0;
        currentSong = song;
        currentSongData = NSMutableData();
        currentSongChunkCount = song.numberOfChunks;
        recievedChunks = [NSData?](count: currentSongChunkCount, repeatedValue: nil);
    }
    
    func prepareForChunk(chunkNumber: String, songId: String, fromPeer peer: MCPeerID) {
        let chunkData = ["type" : "readyToRecieveChunk", "chunkNumber" : "\(chunkNumber)", "songId" : "\(songId)"];
        let jsonString = "\(String.stringFromJson(chunkData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                try SessionManager.sharedInstance.session.sendData(data, toPeers: [peer], withMode: .Reliable);
            } catch {
                print("error sending chunkData to player");
            }
        }
    }
    
    func sendNextChunkFromPeer(peer: MCPeerID) {
        let chunkData = ["type" : "didRecieveChunk"];
        let jsonString = "\(String.stringFromJson(chunkData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                try SessionManager.sharedInstance.session.sendData(data, toPeers: [peer], withMode: .Reliable);
            } catch {
                print("error sending chunkData to player");
            }
        }
    }
    
    func sendAllChunksDoneToPeer(peer: MCPeerID) {
        let chunkData = ["type" : "allChunksDone"];
        let jsonString = "\(String.stringFromJson(chunkData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                try SessionManager.sharedInstance.session.sendData(data, toPeers: [peer], withMode: .Reliable);
            } catch {
                print("error sending chunkData to player");
            }
        }
    }
    
    func addNodeChunk(chunkNumber: Int, musicData: NSData, peer: MCPeerID) {
        recievedChunks[chunkNumber] = musicData;
        chunksRecieved += 1;
        
        if chunksRecieved == currentSongChunkCount {
            songFinished()
            //sendAllChunksDoneToPeer(peer);
        } else {
            sendNextChunkFromPeer(peer);
        }
    }
    
    func songFinished() {
        for index in 0..<recievedChunks.count {
            if let data = recievedChunks[index] {
                currentSongData.appendData(data);
            }
        }
        
        if let _ = currentSong {
            SongManager.sharedInstance.songDownloaded(currentSong!, data: currentSongData);
        }
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