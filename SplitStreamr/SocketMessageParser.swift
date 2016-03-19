//
//  SocketMessageParser.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol SocketMessageParserDelegate {
    func didCreateSession(sessionId: String);
    // func didFailToCreateSession(error: NSError);
    
    func didJoinSession(sessionId: String);
    // func didFailToJoinSession(error: NSError);
    
    // func didFailToStartSongStream(error: NSError);
    func didFailWithError(error: NSError);
    
    func willRecieveChunk(songId: String, chunkNumber: Int);
    
    func didFinishStreamingSong(songId: String);
}

class SocketMessageParser: NSObject {
    var delegate : SocketMessageParserDelegate?;
    var messageClosureMap : Dictionary<String, (jsonObject: JSON) -> Void>?;
    
    override init() {
        super.init();
        messageClosureMap = getMessageClosureMap();
    }
    
    func parseJsonString(jsonString: String) {
        if let dataFromString = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromString);
            
            if let message = json["message"].string {
                messageClosureMap?[message]?(jsonObject: json);
            } else {
                // TODO: Handle Error
                debugLog("Unable to parse json string");
            }
        }
    }
    
    func parseData(data: NSData) {
        
    }
    
    func getMessageClosureMap() -> Dictionary<String, (jsonObject: JSON) -> Void> {
        var tempDictionary = Dictionary<String, (jsonObject: JSON) -> Void>();
        tempDictionary["new session"] = { (jsonObject: JSON) -> Void in
            self.delegate?.didCreateSession(jsonObject["session"].stringValue);
        };
        
        tempDictionary["join session"] = { (jsonObject: JSON) -> Void in
            self.delegate?.didJoinSession(jsonObject["session"].stringValue);
        };
        
        tempDictionary["error"] = { (jsonObject: JSON) -> Void in
            self.delegate?.didFailWithError(NSError(localizedDescription: jsonObject["error"].stringValue));
        };
        
        tempDictionary["chunk number"] = { (jsonObject: JSON) -> Void in
            let chunkNum = jsonObject["chunk"].intValue;
            let songId = jsonObject["song"].stringValue;
            
            self.delegate?.willRecieveChunk(songId, chunkNumber: chunkNum);
        };
        
        tempDictionary["song finished"] = { (jsonObject: JSON) -> Void in
            let songId = jsonObject["song"].stringValue;
            
            self.delegate?.didFinishStreamingSong(songId);
        };
        
        return tempDictionary;
    }
}
