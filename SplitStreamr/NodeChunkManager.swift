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
        let musicString = musicData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0));
        
        let numberAndData = ["chunkNumber" : "\(chunkNumber)", "musicData" : musicString];
    
            if let json = JSON(rawValue: numberAndData) {
                do {
                    let data = try json.rawData();
                    
                    let outputStream = try SessionManager.sharedInstance.session.startStreamWithName("\(songId)\(chunkNumber)", toPeer: self.playerPeer);
                    outputStream.delegate = self;
                    outputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode);
                    outputStream.open();
                    print("write to output stream");
                    outputStream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length);
                    print("finished writing chunk#\(chunkNumber) to output stream");
                } catch {
                    print("Error sending data over mesh.")
                }
            } else {
                print("Error jsoning data")
            }
    }
    
    func didFinishReceivingSong(songId: String) {
        
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
                print("Stream Has Space Available");
            default:
                break;
        }
    }
}
