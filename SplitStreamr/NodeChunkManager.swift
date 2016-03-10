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
    
    var sessionId: String!;
    var playerPeer: MCPeerID!;
    
    var outputStream: NSOutputStream?;
    
    var hasRecievedSongChunk: Bool = false;
    
    var chunkBacklog : [String : NSData] = [:];
    
    var dataDownloadedSoFar = 0
    
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
    
    func preparePlayerForChunk(chunkNumber: String, songId: String) {
        let chunkData = ["type" : "readyToSendChunk", "chunkNumber" : "\(chunkNumber)", "songId" : "\(songId)"];
        let jsonString = "\(String.stringFromJson(chunkData)!)";
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                try SessionManager.sharedInstance.session.sendData(data, toPeers: [self.playerPeer], withMode: .Reliable);
            } catch {
                print("error sending chunkData to player");
            }
        }
    }
    
    func sendChunk(chunkNumber: String, songId: String) {
        if let musicData = chunkBacklog["\(chunkNumber)\(songId)"] {
            chunkBacklog.removeValueForKey("\(chunkNumber)\(songId)");
            let chunkData : NSMutableData = musicData.mutableCopy() as! NSMutableData;
            chunkData.appendData("]".dataUsingEncoding(NSUTF8StringEncoding)!);
            do {
                outputStream = try SessionManager.sharedInstance.session.startStreamWithName("\(songId)\(SessionManager.sharedInstance.myPeerId)\(NSTimeIntervalSince1970)" , toPeer: self.playerPeer);
                outputStream!.delegate = self;
                outputStream!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode);
                outputStream!.open();
                print("open output stream for song \(songId)");
                print("write data of bytes: \(chunkData.length)");
                outputStream!.write(UnsafePointer<UInt8>(chunkData.bytes), maxLength: chunkData.length);
            } catch let error as NSError {
                print("Error sending data over mesh. \(error.localizedDescription)");
            }
        }
    }
    
    func sendNextChunk() {
        if let musicData : NSData? = chunkBacklog.first!.1 {
            chunkBacklog.removeAtIndex(chunkBacklog.indexForKey(chunkBacklog.first!.0)!)
            let chunkData : NSMutableData = musicData!.mutableCopy() as! NSMutableData;
            chunkData.appendData("]".dataUsingEncoding(NSUTF8StringEncoding)!);
            print("write data of bytes: \(chunkData.length)");
            outputStream!.write(UnsafePointer<UInt8>(chunkData.bytes), maxLength: chunkData.length);
        }
    }
    
    func allChunksDone() {
//        let data = "[".dataUsingEncoding(NSUTF8StringEncoding)!;
//        print("write data of bytes: \(data.length)");
//        outputStream!.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length);
        outputStream!.close()
    }
}

extension NodeChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData) {
        if !hasRecievedSongChunk {
            preparePlayerForChunk("\(chunkNumber)", songId: songId);
        }
        
        chunkBacklog["\(chunkNumber)\(songId)"] = musicData;
    }
    
    func didFinishReceivingSong(songId: String) {
        print("Finished receiving song: \(songId)");
    }
    
    func sessionIdReceived(sessionId: String) {
        
    }
    
    func errorRecieved(error: NSError) {
        print(error.debugDescription);
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
