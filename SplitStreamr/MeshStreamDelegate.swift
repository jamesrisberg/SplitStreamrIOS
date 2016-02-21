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
        super.init()
    }
    
    convenience init(stream: NSInputStream, chunkData: NSMutableData) {
        self.init();
        self.stream = stream;
    }
}

extension MeshStreamDelegate : NSStreamDelegate {
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch (eventCode) {
            case NSStreamEvent.ErrorOccurred:
                NSLog("ErrorOccurred")
            case NSStreamEvent.EndEncountered:
                NSLog("EndEncountered")
            case NSStreamEvent.None:
                NSLog("None")
            case NSStreamEvent.HasBytesAvailable:
                NSLog("HasBytesAvaible")
                var buffer = [UInt8](count: 4096, repeatedValue: 0)
                if (aStream == self.stream) {
                    while (stream.hasBytesAvailable) {
                        let len = stream.read(&buffer, maxLength: buffer.count);
                        if len > 0 {
                            chunkData.appendBytes(&buffer, length: len);
                        }
                    }
                }
            case NSStreamEvent():
                NSLog("allZeros")
            case NSStreamEvent.OpenCompleted:
                NSLog("OpenCompleted")
            case NSStreamEvent.HasSpaceAvailable:
                NSLog("HasSpaceAvailable")
            default:
                break
        }
    }
}