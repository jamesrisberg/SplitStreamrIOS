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
        if let stream = outputStream {
            let musicString = musicData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0));
            
            let numberAndData = ["chunkNumber" : "\(chunkNumber)", "musicData" : musicString];
            let jsonString = ",\(String.stringFromJson(numberAndData))";
            let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding);
            stream.write(UnsafePointer<UInt8>(data!.bytes), maxLength: data!.length);
        }
        else {
            do {
                outputStream = try SessionManager.sharedInstance.session.startStreamWithName("\(songId)", toPeer: self.playerPeer);
                outputStream!.delegate = self;
                outputStream!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode);
                outputStream!.open();
                
                let musicString = musicData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0));
                
                let numberAndData = ["chunkNumber" : "\(chunkNumber)", "musicData" : musicString];
                let jsonString = "[\(String.stringFromJson(numberAndData))";
                let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding);
                outputStream!.write(UnsafePointer<UInt8>(data!.bytes), maxLength: data!.length);
            } catch {
                print("Error sending data over mesh.")
            }
        }
    }
    
    func didFinishReceivingSong(songId: String) {
        let data = "]".dataUsingEncoding(NSUTF8StringEncoding);
        outputStream!.write(UnsafePointer<UInt8>(data!.bytes), maxLength: data!.length);
        outputStream!.close();
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
