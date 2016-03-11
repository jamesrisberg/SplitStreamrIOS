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
    
    var chunkBacklog : [String : NSData] = [:];
    
    var dataDownloadedSoFar = 0;
    
    override init() {
        super.init();
    }
    
    convenience init(playerPeer: MCPeerID) {
        self.init();
        self.playerPeer = playerPeer;
    }
    
    func joinSession(sessionId: String) {
        self.sessionId = sessionId;
    }
    
    func preparePlayerForStream() {
        debugLog("Node sending readyToSendStream data to player");
        let chunkData = ["type" : "readyToSendStream"];
        let jsonString = "\(String.stringFromJson(chunkData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                try SessionManager.sharedInstance.session.sendData(data, toPeers: [self.playerPeer], withMode: .Reliable);
            } catch {
                print("error sending readyToSendStream to player");
            }
        }
    }
    
    func setupStreamWithPlayer(songId: String) {
        do {
            outputStream = try SessionManager.sharedInstance.session.startStreamWithName("\(songId)\(SessionManager.sharedInstance.myPeerId)\(NSTimeIntervalSince1970)" , toPeer: self.playerPeer);
            outputStream!.delegate = self;
            outputStream!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode);
            outputStream!.open();
            print("open output stream for song \(songId)");
        } catch let error as NSError {
            print("Error sending data over mesh. \(error.localizedDescription)");
        }
    }
    
    func preparePlayerForChunk() {
        debugLog("Node sending readyToSendChunk to player");
        if let chunkNumber = Array(chunkBacklog.keys).minElement() {
            let musicData = chunkBacklog[chunkNumber];
            let jsonStr = buildSingleChunkJSONString(chunkNumber, musicData: musicData!);
            var length = 0;
            if let data = jsonStr.dataUsingEncoding(NSUTF8StringEncoding) {
                length = data.length;
            }
            debugLog("musicData.length = \(musicData!.length)");
            let chunkData = ["type" : "readyToSendChunk", "chunkNumber" : chunkNumber, "chunkSize" : "\(length)"];
            let jsonString = "\(String.stringFromJson(chunkData)!)";
            if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
                do {
                    try SessionManager.sharedInstance.session.sendData(data, toPeers: [self.playerPeer], withMode: .Reliable);
                } catch {
                    print("error sending readyToSendChunk to player");
                }
            }
        }
    }
    
    func sendChunk(chunkNumber: String, songId: String) {
        debugLog("sendChunk called on NCM");
        if let musicData = chunkBacklog[chunkNumber] {
            chunkBacklog.removeValueForKey(chunkNumber);
            
            let jsonString = buildSingleChunkJSONString(chunkNumber, musicData: musicData);
            if let dataToStream = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
                var buffer = [UInt8](count: dataToStream.length, repeatedValue: 0);
                dataToStream.getBytes(&buffer, length: dataToStream.length);
                print("write data of bytes: \(dataToStream.length)");
                outputStream!.write(&buffer, maxLength: dataToStream.length);
            }
        }
    }
    
    func allChunksDone() {
        outputStream!.close()
    }
    
    func buildSingleChunkJSONString(chunkNumber: String, musicData: NSData) -> String {
        let musicString = musicData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0));
        let numberAndData = ["chunkNumber" : chunkNumber, "musicData" : musicString];
        let jsonString = "\(String.stringFromJson(numberAndData)!)";
        
        return jsonString;
    }
}

extension NodeChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData) {
        debugLog("Node recieved music piece");
        if !hasRecievedSongChunk {
            hasRecievedSongChunk = true;
            preparePlayerForStream();
        }
        
        chunkBacklog["\(chunkNumber)"] = musicData;
    }
    
    func didFinishReceivingSong(songId: String) {
        debugLog("Finished receiving song: \(songId)");
    }
    
    func sessionIdReceived(sessionId: String) {
        
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
                print("Stream Has Space Available");
            case NSStreamEvent.EndEncountered:
                print("Stream End Encountered");
            default:
                break;
        }
    }
}
