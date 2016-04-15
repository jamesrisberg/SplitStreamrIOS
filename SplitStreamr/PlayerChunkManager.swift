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
import CryptoSwift

class PlayerChunkManager: NSObject {
    
    var sessionId: String?;
    var key: String?;
    
    var streamDelegates: [MCPeerID : NodeStreamManager] = [:];
    var recievedChunks: [NSData?] = [];
    
    var chunksRecieved = 0;
    var currentSongData: NSMutableData = NSMutableData();
    var currentSongChunkCount: Int = 0;
    var currentSong: Song?;
    var nextChunkToQueue = 0;
    
    var messageClosureMap : Dictionary<String, (jsonObject: JSON, peer: MCPeerID) -> Void>?;
    
    override init() {
        super.init();
        
        messageClosureMap = getMessageClosureMap();
    }
    
    func prepareForSong(songID: String) {
        chunksRecieved = 0;
        nextChunkToQueue = 0;
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
        debugLog("\(SessionManager.sharedInstance.myPeerId.displayName) received chunk \(chunkNumber) from \(peer.displayName)");
        
        queueChunk(chunkNumber, musicData: musicData);
    }
    
    func queueChunk(chunkNumber: Int, musicData: NSData) {
        debugLog("Queueing chunk \(chunkNumber) for playback");
        recievedChunks[chunkNumber] = musicData;
        chunksRecieved += 1;
        
//        var decrypted: [UInt8] = [];
//        let encryptedBytes = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(musicData.bytes), count: musicData.length))
//        do {
//            decrypted = try AES(key: key!, iv: "", blockMode: .CTR).decrypt(encryptedBytes, padding: PKCS7());
//        } catch {
//            debugLog("Decryption error");
//        }
//        
//        let decryptedData = NSData(bytes: decrypted);
        
        if chunkNumber == nextChunkToQueue {
            nextChunkToQueue += 1;
            SongManager.sharedInstance.queueChunk(chunkNumber, data: musicData);
        }
        
        if chunkNumber == currentSongChunkCount {
            SongManager.sharedInstance.songDownloaded();
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
}

extension PlayerChunkManager : ChunkManager {
    func handleHandshakingMessage(json: JSON, peer: MCPeerID) {
        if let message = json["message"].string {
            messageClosureMap?[message]?(jsonObject: json, peer: peer);
        } else {
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
}

extension PlayerChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData) {
        debugLog("\(SessionManager.sharedInstance.myPeerId.displayName) received chunk \(chunkNumber) from server");
        
        queueChunk(chunkNumber, musicData: musicData);
    }
    
    func didFinishReceivingSong(songId: String) {
        
    }
    
    func sessionIdReceived(sessionId: String, key: String) {
        self.sessionId = sessionId;
        self.key = key;
        SessionManager.sharedInstance.setSessionId(sessionId);
    }
    
    func errorRecieved(error: NSError) {
        debugLog(error.debugDescription);
    }
    
    func didEstablishConnection() {
        SessionManager.sharedInstance.createNewSession();
    }
}