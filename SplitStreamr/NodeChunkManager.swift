//
//  NodeChunkManager.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import SwiftyJSON

class NodeChunkManager: NSObject {
    
    var sessionId: String?;
    var playerPeer: MCPeerID!;
    
    var outputStream: NSOutputStream?;
    
    var hasRecievedSongChunk: Bool = false;
    var chunkBacklog : [Int : NSData] = [:];
    
    var messageClosureMap : Dictionary<String, (jsonObject: JSON, peer: MCPeerID) -> Void>?;
    
    var timer: NSTimer?
    
    override init() {
        super.init();
        
        messageClosureMap = getMessageClosureMap();
    }
    
    convenience init(playerPeer: MCPeerID) {
        self.init();
        self.playerPeer = playerPeer;
    }
    
    func joinSession(sessionId: String) {
        self.sessionId = sessionId;
    }
    
    func preparePlayerForStream() {
        SessionManager.sharedInstance.sendSimpleJSONMessage("readyToSendStream", toPeer: playerPeer);
    }
    
    func setupStreamWithPlayer() {
        debugLog("\(SessionManager.sharedInstance.myPeerId.displayName) starting stream with \(playerPeer.displayName)");
        do {
            outputStream = try SessionManager.sharedInstance.session.startStreamWithName("\(SessionManager.sharedInstance.myPeerId)\(NSTimeIntervalSince1970)" , toPeer: self.playerPeer);
            outputStream!.delegate = self;
            outputStream!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode);
            outputStream!.open();
        } catch let error as NSError {
            debugLog("Error establishing stream. \(error.localizedDescription)");
        }
    }
    
    func preparePlayerForChunk() {
        if chunkBacklog.count < 1 {
            debugLog("Chunk backlog is empty! Rechecking in 0.3s");
            timer = NSTimer(timeInterval: 0.3, target: self, selector: #selector(NodeChunkManager.recheckForChunk), userInfo: nil, repeats: false);
            NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes);
        } else if let chunkNumber = Array(chunkBacklog.keys).minElement() {
            print(Array(chunkBacklog.keys).minElement())
            if let length = getSizeOfChunkForNumber(chunkNumber) {
                debugLog("\(SessionManager.sharedInstance.myPeerId.displayName) sending readyToSendChunk for Chunk \(chunkNumber) to \(playerPeer.displayName)");
                let chunkData = ["message" : "readyToSendChunk", "chunkNumber" : chunkNumber, "chunkSize" : "\(length)"];
                let jsonString = "\(String.stringFromJson(chunkData)!)";
                SessionManager.sharedInstance.sendJSONString(jsonString, toPeer: playerPeer);
            }
        } else {
            debugLog("Error finding next chunk number");
        }
    }
    
    func recheckForChunk() {
        timer?.invalidate();
        preparePlayerForChunk();
    }
    
    func sendChunk(chunkNumber: Int) {
        if let musicData = chunkBacklog[chunkNumber] {
            chunkBacklog.removeValueForKey(chunkNumber);
            
            let jsonString = buildSingleChunkJSONString(chunkNumber, musicData: musicData);
            if let dataToStream = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
                var buffer = [UInt8](count: dataToStream.length, repeatedValue: 0);
                dataToStream.getBytes(&buffer, length: dataToStream.length);
                outputStream!.write(&buffer, maxLength: dataToStream.length);
            }
        } else {
            debugLog("Error getting chunk number \(chunkNumber)");
        }
    }
    
    func allChunksDone() {
        hasRecievedSongChunk = false;
        chunkBacklog = [:];
        timer?.invalidate();
        outputStream?.close();
        outputStream = nil;
    }
    
    func getSizeOfChunkForNumber(chunkNumber: Int) -> Int? {
        let musicData = chunkBacklog[chunkNumber];
        let jsonString = buildSingleChunkJSONString(chunkNumber, musicData: musicData!);
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            return data.length
        } else {
            debugLog("Error getting chunk size");
            return nil;
        }
    }
    
    func buildSingleChunkJSONString(chunkNumber: Int, musicData: NSData) -> String {
        let musicString = musicData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0));
        let numberAndData = ["chunkNumber" : chunkNumber, "musicData" : musicString];
        let jsonString = "\(String.stringFromJson(numberAndData)!)";
        
        return jsonString;
    }
    
    func getMessageClosureMap() -> Dictionary<String, (jsonObject: JSON, peer: MCPeerID) -> Void> {
        var tempDictionary = Dictionary<String, (jsonObject: JSON, peer: MCPeerID) -> Void>();
        tempDictionary["readyToRecieveStream"] = { (jsonObject: JSON, peer: MCPeerID) -> Void in
            self.setupStreamWithPlayer();
        };
        
        tempDictionary["didRecieveStream"] = { (jsonObject: JSON, peer: MCPeerID) -> Void in
            self.preparePlayerForChunk();
        };
        
        tempDictionary["readyToRecieveChunk"] = { (jsonObject: JSON, peer: MCPeerID) -> Void in
            self.sendChunk(jsonObject["chunkNumber"].intValue);
        };
        
        tempDictionary["didRecieveChunk"] = { (jsonObject: JSON, peer: MCPeerID) -> Void in
            self.preparePlayerForChunk();
        };
        
        tempDictionary["allChunksDone"] = { (jsonObject: JSON, peer: MCPeerID) -> Void in
            self.allChunksDone();
        };
        
        return tempDictionary;
    }
}

extension NodeChunkManager : ChunkManager {
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

extension NodeChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData) {
        debugLog("\(SessionManager.sharedInstance.myPeerId.displayName) recieved chunk \(chunkNumber) from server");
        if !hasRecievedSongChunk {
            hasRecievedSongChunk = true;
            preparePlayerForStream();
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("DownloadedData", object: nil, userInfo: ["dataSize": musicData.arrayOfBytes().count]);
        chunkBacklog[chunkNumber] = musicData;
    }
    
    func didFinishReceivingSong(songId: String) {
    }
    
    func sessionIdReceived(sessionId: String, key: String) {
    }
    
    func errorRecieved(error: NSError) {
        debugLog(error.debugDescription);
    }
    
    func didEstablishConnection() {
        SessionManager.sharedInstance.connectToSession();
    }
}

extension NodeChunkManager : NSStreamDelegate {
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch(eventCode) {
            case NSStreamEvent.HasSpaceAvailable:
                debugLog("Stream Has Space Available");
            case NSStreamEvent.EndEncountered:
                debugLog("Stream End Encountered");
            default:
                break;
        }
    }
}
