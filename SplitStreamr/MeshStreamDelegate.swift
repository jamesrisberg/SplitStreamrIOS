//
//  MeshStreamDelegate.swift
//  SplitStreamr
//
//  Created by James on 2/21/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation

class MeshStreamDelegate: NSObject {
    
    var stream: NSInputStream!;
    var chunkData: NSMutableData = NSMutableData();
    
    override init() {
        super.init();
    }
    
    convenience init(stream: NSInputStream) {
        self.init();
        self.stream = stream;
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
                        let len = self.stream.read(&buffer, maxLength: buffer.count);
                                                
                        if len > 0 {
                            chunkData.appendBytes(&buffer, length: len);
                            print(String(data: NSData(bytes: buffer, length: len), encoding: NSUTF8StringEncoding));
                        }
                        print("last byte: \(buffer[len-1])");
                        print("chunkData size: \(chunkData.length)");
                        if buffer[len-1] == 93 {
                            print("stream closed and chunks finished");
                            self.stream.close();
                            SessionManager.sharedInstance.chunkFinishedStreaming(chunkData, delegate: self);
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