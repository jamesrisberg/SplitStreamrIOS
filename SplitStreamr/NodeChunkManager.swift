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
    
    var dataStuff: NSMutableData = NSMutableData();
    
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
}

extension NodeChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData) {
        if hasRecievedSongChunk {
            let musicString = musicData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0));
            
            let numberAndData = ["chunkNumber" : "\(chunkNumber)", "musicData" : musicString];
            let jsonString = ",\(String.stringFromJson(numberAndData)!)";
            let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding);
            self.dataStuff.appendData(data!);
        }
        else {
            print("recieved first song chunk");
            hasRecievedSongChunk = true;
            let musicString = musicData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0));
            
            let numberAndData = ["chunkNumber" : "\(chunkNumber)", "musicData" : musicString];
            let jsonString = "[\(String.stringFromJson(numberAndData)!)";
            let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding);
            dataStuff.appendData(data!);
        }
    }
    
    func didFinishReceivingSong(songId: String) {
        print("Finished receiving song: \(songId)");
        hasRecievedSongChunk = false;
        let data = "]".dataUsingEncoding(NSUTF8StringEncoding);
        dataStuff.appendData(data!);
        
        do {
            outputStream = try SessionManager.sharedInstance.session.startStreamWithName("\(songId)\(SessionManager.sharedInstance.myPeerId)\(NSTimeIntervalSince1970)" , toPeer: self.playerPeer);
            outputStream!.delegate = self;
            outputStream!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode);
            outputStream!.open();
            print("open output stream for song \(songId)");
            print("write data of bytes: \(dataStuff.length)");
            outputStream!.write(UnsafePointer<UInt8>(dataStuff.bytes), maxLength: dataStuff.length);
        } catch let error as NSError {
            print("Error sending data over mesh. \(error.localizedDescription)");
        }

        // outputStream!.close();
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
