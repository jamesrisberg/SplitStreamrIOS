//
//  PlayerChunkManager.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import SwiftyJSON

class PlayerChunkManager: NSObject {
    
    var sessionId: String?;
    
    var streamDelegates: [MCPeerID : NodeStreamManager] = [:];
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
    
    func prepareForStream(peer: MCPeerID) {
        streamDelegates[peer] = NodeStreamManager(nodePeerID: peer, delegate: self);
        
        debugLog("player sending readyToRecieveStream");
        let chunkData = ["type" : "readyToRecieveStream"];
        let jsonString = "\(String.stringFromJson(chunkData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            debugLog("jsonString encoded");
            do {
                try SessionManager.sharedInstance.session.sendData(data, toPeers: [peer], withMode: .Reliable);
            } catch {
                print("error sending readyToRecieveStream to node");
            }
        }
    }
    
    func attachStream(peer: MCPeerID, stream: NSInputStream) {
        streamDelegates[peer]?.configureWithStream(stream);
        
        debugLog("player sending didRecieveStream");
        let chunkData = ["type" : "didRecieveStream"];
        let jsonString = "\(String.stringFromJson(chunkData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                try SessionManager.sharedInstance.session.sendData(data, toPeers: [peer], withMode: .Reliable);
            } catch {
                print("error sending didRecieveStream to node");
            }
        }
    }
    
    func prepareForChunk(chunkNumber: String, chunkSize : String, songId: String, fromPeer peer: MCPeerID) {
        streamDelegates[peer]?.prepareForChunkWithSize(Int(chunkSize)!);
        
        debugLog("player sending readyToRecieveChunk");
        let chunkData = ["type" : "readyToRecieveChunk", "chunkNumber" : chunkNumber, "songId" : songId];
        let jsonString = "\(String.stringFromJson(chunkData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                try SessionManager.sharedInstance.session.sendData(data, toPeers: [peer], withMode: .Reliable);
            } catch {
                print("error sending readyToRecieveChunk to node");
            }
        }
    }
    
    func sendNextChunkFromPeer(peer: MCPeerID) {
        let chunkData = ["type" : "didRecieveChunk"];
        let jsonString = "\(String.stringFromJson(chunkData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                debugLog("sending didrecieveChunk to node");
                try SessionManager.sharedInstance.session.sendData(data, toPeers: [peer], withMode: .Reliable);
            } catch {
                print("error sending didRecieveChunk to player");
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
                print("error sending allChunksDone to player");
            }
        }
    }
    
    func addNodeChunk(chunkNumber: Int, musicData: NSData, peer: MCPeerID) {
        debugLog("addNodeChunk called on PCM");
        recievedChunks[chunkNumber] = musicData;
        chunksRecieved += 1;
        
        if chunksRecieved == currentSongChunkCount {
            debugLog("songFinished called form addNodeChunk");
            songFinished()
            //sendAllChunksDoneToPeer(peer);
        } else {
            debugLog("sendNextChunk called from addNodeChunk");
            sendNextChunkFromPeer(peer);
        }
    }
    
    func songFinished() {
        debugLog("songFinished");
        for index in 0..<recievedChunks.count {
            if let data = recievedChunks[index] {
                currentSongData.appendData(data);
            }
        }
        
        if let _ = currentSong {
            debugLog("PCM calls songDownloaded on SongManager");
            SongManager.sharedInstance.songDownloaded(currentSong!, data: currentSongData);
        }
    }
}

extension PlayerChunkManager : NodeStreamDelegate {
    func chunkFinishedStreaming(chunkData: NSMutableData, manager: NodeStreamManager) {
        debugLog("chunkFinishedStreaming called by mesh delegate");
        var error : NSError?
        let json = JSON(data: chunkData, options: NSJSONReadingOptions(rawValue:0), error: &error);
        print("JSON Error: \(error)");
        // TODO: There is an invalid JSON error in here occasionally
        
        if let chunkNumber = json["chunkNumber"].string {
            if let musicString = json["musicData"].string {
                let musicData = NSData(base64EncodedString: musicString, options: NSDataBase64DecodingOptions(rawValue:0));
                addNodeChunk(Int(chunkNumber)!, musicData: musicData!, peer: manager.nodePeerID!);
            } else {
                print("Error getting chunk data: \(json["musicData"].string)");
            }
        } else {
            print("Error getting chunk numba: \(json["chunkNumber"].string)");
        }
    }
    
    func allChunksFinishedStreaming(delegate: NodeStreamManager) {
        
    }
}

extension PlayerChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData) {
        debugLog("Player received music piece");
        recievedChunks[chunkNumber] = musicData;
        chunksRecieved += 1;
        if chunksRecieved == currentSongChunkCount {
            debugLog("Player calls songFinished");
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