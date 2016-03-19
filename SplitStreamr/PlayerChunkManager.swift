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
    
    var messageClosureMap : Dictionary<String, (jsonObject: JSON, peer: MCPeerID) -> Void>?;
    
    override init() {
        super.init();
        
        messageClosureMap = getMessageClosureMap();
    }
    
    func prepareForSong(songID: String) {
        chunksRecieved = 0;
        currentSong = SongManager.sharedInstance.getSongForId(songID);
        currentSongData = NSMutableData();
        currentSongChunkCount = currentSong!.numberOfChunks;
        recievedChunks = [NSData?](count: currentSongChunkCount, repeatedValue: nil);
    }
    
    func prepareForStreamFromPeer(peer: MCPeerID) {
        streamDelegates[peer] = NodeStreamManager(nodePeerID: peer, delegate: self);

        SessionManager.sharedInstance.sendSimpleJSONMessage("readyToRecieveStream", toPeer: peer);
    }
    
    func attachStream(stream: NSInputStream, fromPeer peer: MCPeerID) {
        if let del = streamDelegates[peer] {
            del.configureWithStream(stream);
            
            SessionManager.sharedInstance.sendSimpleJSONMessage("didRecieveStream", toPeer: peer);
        } else {
            debugLog("Stream Delegate for peer \(peer) doesn't exist");
        }
    }
    
    func prepareForChunk(chunkNumber: String, chunkSize : String, fromPeer peer: MCPeerID) {
        if let del = streamDelegates[peer] {
            del.prepareForChunkWithSize(Int(chunkSize)!);
            
            let chunkData = ["message" : "readyToRecieveChunk", "chunkNumber" : chunkNumber];
            let jsonString = "\(String.stringFromJson(chunkData)!)";
            SessionManager.sharedInstance.sendJSONString(jsonString, toPeer: peer);
        } else {
            debugLog("Stream Delegate for peer \(peer) doesn't exist");
        }
    }
    
    func didReceiveChunkFromPeer(peer: MCPeerID) {
        SessionManager.sharedInstance.sendSimpleJSONMessage("didRecieveChunk", toPeer: peer);
    }
    
    func sendAllChunksDoneToPeer(peer: MCPeerID) {
        SessionManager.sharedInstance.sendSimpleJSONMessage("allChunksDone", toPeer: peer);
    }
    
    func addNodeChunk(chunkNumber: Int, musicData: NSData, peer: MCPeerID) {
        debugLog("addNodeChunk called on PCM");
        recievedChunks[chunkNumber] = musicData;
        chunksRecieved += 1;
        
        if chunksRecieved == currentSongChunkCount {
            debugLog("songFinished called from addNodeChunk");
            songFinished()
            sendAllChunksDoneToPeer(peer);
            streamDelegates[peer]?.closeStream();
            streamDelegates.removeValueForKey(peer);
        } else {
            didReceiveChunkFromPeer(peer);
        }
    }
    
    func songFinished() {
        debugLog("songFinished");
        for index in 0..<recievedChunks.count {
            if let data = recievedChunks[index] {
                currentSongData.appendData(data);
            } else {
                debugLog("Recieved chunk \(index) not found!");
            }
        }
        
        if let _ = currentSong {
            debugLog("PCM calls songDownloaded on SongManager");
            SongManager.sharedInstance.songDownloaded(currentSong!, data: currentSongData);
        }
    }
    
    func getMessageClosureMap() -> Dictionary<String, (jsonObject: JSON, peer: MCPeerID) -> Void> {
        var tempDictionary = Dictionary<String, (jsonObject: JSON, peer: MCPeerID) -> Void>();
        
        tempDictionary["songID"] = { (jsonObject: JSON, peer: MCPeerID) -> Void in
            self.prepareForSong(jsonObject["songID"].stringValue);
        };
        
        tempDictionary["readyToSendStream"] = { (jsonObject: JSON, peer: MCPeerID) -> Void in
            self.prepareForStreamFromPeer(peer);
        };
        
        tempDictionary["readyToSendChunk"] = { (jsonObject: JSON, peer: MCPeerID) -> Void in
            self.prepareForChunk(jsonObject["chunkNumber"].stringValue, chunkSize: jsonObject["chunkSize"].stringValue, fromPeer: peer);
        };
        
        return tempDictionary;
    }
    
    func getJSONMessage(message: String) -> NSData? {
        let messageData = ["message" : message];
        let jsonString = "\(String.stringFromJson(messageData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            return data;
        } else {
            debugLog("Error building JSON message");
            return nil;
        }
    }
}

extension PlayerChunkManager : ChunkManager {
    func handleHandshakingMessage(json: JSON, peer: MCPeerID) {
        if let message = json["message"].string {
            messageClosureMap?[message]?(jsonObject: json, peer: peer);
        }
        else {
            // TODO: Handle Error
            debugLog("Unable to parse JSON");
        }
    }
}

extension PlayerChunkManager : NodeStreamDelegate {
    func chunkFinishedStreaming(chunkData: NSMutableData, manager: NodeStreamManager) {
        debugLog("chunkFinishedStreaming called by mesh delegate");
        var error : NSError?
        let json = JSON(data: chunkData, options: NSJSONReadingOptions(rawValue:0), error: &error);
        if let _ = error {
            debugLog("JSON Error: \(error)");
        }
        
        if let chunkNumber = json["chunkNumber"].string {
            if let musicString = json["musicData"].string {
                let musicData = NSData(base64EncodedString: musicString, options: NSDataBase64DecodingOptions(rawValue:0));
                addNodeChunk(Int(chunkNumber)!, musicData: musicData!, peer: manager.nodePeerID!);
            } else {
                debugLog("Error getting chunk data: \(json["musicData"].string)");
            }
        } else {
            debugLog("Error getting chunk numba: \(json["chunkNumber"].string)");
        }
    }
    
    func allChunksFinishedStreaming(delegate: NodeStreamManager) {
        
    }
}

extension PlayerChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData) {
        debugLog("\(SessionManager.sharedInstance.myPeerId.displayName) received chunk \(chunkNumber) from server");
        
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
        debugLog(error.debugDescription);
    }
    
    func didEstablishConnection() {
        SessionManager.sharedInstance.createNewSession();
    }
}