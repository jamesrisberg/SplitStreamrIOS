//
//  NodeStreamManager.swift
//  SplitStreamr
//
//  Created by James on 2/21/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import Darwin
import MultipeerConnectivity

protocol NodeStreamDelegate {
    func chunkFinishedStreaming(chunkData: NSMutableData, manager: NodeStreamManager);
    func allChunksFinishedStreaming(delegate: NodeStreamManager);
}

class NodeStreamManager: NSObject {
    
    var stream: NSInputStream!;
    var chunkData: NSMutableData = NSMutableData();
    var nodePeerID: MCPeerID?;
    var delegate: NodeStreamDelegate?;
    var incomingChunkSize: Int?;
    
    override init() {
        super.init();
    }
    
    convenience init(nodePeerID: MCPeerID, delegate: NodeStreamDelegate) {
        self.init();
        self.nodePeerID = nodePeerID;
        self.delegate = delegate;
        debugLog("Mesh Delegate made");
    }
    
    func configureWithStream(stream: NSInputStream) {
        self.stream = stream;
        self.stream.delegate = self;
        self.stream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode);
        self.stream.open();
        
        debugLog("Mesh Delegate configed with stream");
    }
    
    func prepareForChunkWithSize(chunkSize: Int) {
        debugLog("incomingChunkSize = \(chunkSize)");
        incomingChunkSize = chunkSize;
    }
    
    func closeStream() {
        self.stream.close();
    }
}

extension NodeStreamManager : NSStreamDelegate {
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch (eventCode) {
            case NSStreamEvent.ErrorOccurred:
                debugLog("ErrorOccurred")
            case NSStreamEvent.EndEncountered:
                debugLog("EndEncountered")
            case NSStreamEvent.None:
                debugLog("None")
            case NSStreamEvent.HasBytesAvailable:
                debugLog("HasBytesAvail");
                var buffer = [UInt8](count: incomingChunkSize!, repeatedValue: 0)
                //if (aStream == self.stream) {
                    while (self.stream.hasBytesAvailable) {
                        // usleep(20000);
                        // sleep(2);
                        let len = self.stream.read(&buffer, maxLength: buffer.count);
                                                
                        if len > 0 {
                            chunkData.appendBytes(&buffer, length: len);
                        }
                        debugLog("chunkData size: \(chunkData.length)");
                        if chunkData.length == incomingChunkSize {
                            debugLog("chunk finished");
                            delegate!.chunkFinishedStreaming(chunkData, manager: self);
                            incomingChunkSize = nil;
                            chunkData = NSMutableData();
                        }
                    }
                //}

            case NSStreamEvent():
                debugLog("allZeros")
            case NSStreamEvent.OpenCompleted:
                debugLog("OpenCompleted")
            case NSStreamEvent.HasSpaceAvailable:
                debugLog("HasSpaceAvailable")
            default:
                break
        }
    }
}