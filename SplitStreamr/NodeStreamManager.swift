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
        
        // Uncomment to switch to the delegate method of reading from the stream
        //self.stream.delegate = self;
        
        self.stream.open();
    }
    
    func prepareForChunkWithSize(chunkSize: Int) {
        incomingChunkSize = chunkSize;
        
        // Uncomment to debug the delegate method
        //debugLog(self.stream.delegate.debugDescription);
        
        // Uncomment to switch to the explicit method of reading from the stream
        startMonitoringStream();
    }
    
    func closeStream() {
        self.stream.close();
    }
}

extension NodeStreamManager : NSStreamDelegate {
    func startMonitoringStream() {
        timer = NSTimer(timeInterval: 0.4, target: self, selector: #selector(NodeStreamManager.streamStatus), userInfo: nil, repeats: false);
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes);
    }
    
    func streamStatus() {
        self.timer?.invalidate();
        
        if (stream.hasBytesAvailable) {
            self.readBytes(stream);
        } else {
            self.startMonitoringStream();
        }
    }
    
    func readBytes(aStream: NSStream) {
        var buffer = [UInt8](count: incomingChunkSize!, repeatedValue: 0);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            
            while (self.stream.hasBytesAvailable) {
                let len = self.stream.read(&buffer, maxLength: buffer.count);
                
                if len > 0 {
                    self.chunkData.appendBytes(&buffer, length: len);
                }

                debugLog("chunkData size: \(self.chunkData.length)");
                if self.chunkData.length == self.incomingChunkSize {
                    self.chunkFinished = true;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if self.chunkFinished {
                    debugLog("Got all the data!");
                    self.delegate!.chunkFinishedStreaming(self.chunkData, manager: self);
                    self.chunkData = NSMutableData();
                    self.chunkFinished = false;
                } else {
                    self.startMonitoringStream();
                }
            });
        });
    }

    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        debugLog("event");
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
