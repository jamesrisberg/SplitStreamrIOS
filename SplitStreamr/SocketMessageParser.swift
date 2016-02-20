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
            }
            else {
                // TODO: Handle Error
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
        
        return tempDictionary;
    }
}
