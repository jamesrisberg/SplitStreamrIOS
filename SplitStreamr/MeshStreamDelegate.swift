//
//  MeshStreamDelegate.swift
//  SplitStreamr
//
//  Created by James on 2/21/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import Darwin
import MultipeerConnectivity

class MeshStreamDelegate: NSObject {
    
    var stream: NSInputStream!;
    var chunkData: NSMutableData = NSMutableData();
    var nodePeerID: MCPeerID?;
    
    override init() {
        super.init();
    }
    
    convenience init(stream: NSInputStream, nodePeerID: MCPeerID) {
        self.init();
        self.stream = stream;
        self.nodePeerID = nodePeerID;
        stream.delegate = self;
        stream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode);
        stream.open();
    }
}

extension MeshStreamDelegate : NSStreamDelegate {
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch (eventCode) {
            case NSStreamEvent.ErrorOccurred:
                print("ErrorOccurred")
            case NSStreamEvent.EndEncountered:
                print("EndEncountered")
            case NSStreamEvent.None:
                print("None")
            case NSStreamEvent.HasBytesAvailable:
                //print("HasBytesAvail");
                var buffer = [UInt8](count: 4096, repeatedValue: 0)
                //if (aStream == self.stream) {
                    while (self.stream.hasBytesAvailable) {
                        usleep(20000);
                        // sleep(2);
                        let len = self.stream.read(&buffer, maxLength: buffer.count);
                                                
                        if len > 0 {
                            chunkData.appendBytes(&buffer, length: len);
                        }
                        print("chunkData size: \(chunkData.length)");
                        if buffer[len-1] == 93 {
                            print("chunk finished");
                            SessionManager.sharedInstance.chunkFinishedStreaming(chunkData, delegate: self);
                            chunkData = NSMutableData();
                        }
                    }
                //}

            case NSStreamEvent():
                print("allZeros")
            case NSStreamEvent.OpenCompleted:
                print("OpenCompleted")
            case NSStreamEvent.HasSpaceAvailable:
                print("HasSpaceAvailable")
            default:
                break
        }
    }
}