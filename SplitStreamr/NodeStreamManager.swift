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
}

class NodeStreamManager: NSObject {
    
    var stream: NSInputStream!;
    var chunkData: NSMutableData = NSMutableData();
    var nodePeerID: MCPeerID?;
    var delegate: NodeStreamDelegate?;
    var incomingChunkSize: Int?;
    var timer: NSTimer?;
    var chunkFinished = false;
    
    override init() {
        super.init();
    }
    
    convenience init(nodePeerID: MCPeerID, delegate: NodeStreamDelegate) {
        self.init();
        self.nodePeerID = nodePeerID;
        self.delegate = delegate;
    }
    
    func configureWithStream(stream: NSInputStream) {
        self.stream = stream;
        self.stream.delegate = self
        self.stream.open();
    }
    
    func prepareForChunkWithSize(chunkSize: Int) {
        incomingChunkSize = chunkSize;
        //startMonitoringStream();
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
