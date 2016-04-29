//
//  NetworkObjects.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation

struct UserData: CustomStringConvertible, Equatable {    
    var id: String
    var email: String
    var firstName: String?
    var lastName: String?
    
    init(id: String, email: String, firstName: String?, lastName: String?) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.id = randomStringWithLength(8) as String
    }
    
    init(email: String, firstName: String?, lastName: String?) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.id = randomStringWithLength(8) as String
    }
    
    init(fromJson: Dictionary<String, AnyObject>) {
        if let id = fromJson["_id"] as? String {
            self.id = id
        } else {
            self.id = ""
            debugLog("ID not sent")
        }
        
        let jsonEmail = fromJson["email"] as? String
        
        if let email = jsonEmail {
            self.email = email
        }
        else {
            email = "noemail"
        }
 
        firstName = fromJson["firstName"] as? String
        lastName = fromJson["lastName"] as? String
    }
    
    var description: String {
        return "email: \(email) id: \(id)"
    }
}

func ==(lhs: UserData, rhs: UserData) -> Bool {
    return lhs.id == rhs.id
}

struct Song: CustomStringConvertible {
    var id: String;
    var name: String;
    var artist: String;
    var length: Float; // Length in Seconds
    var numberOfChunks: Int;
    var fixedChunkSize: Float; // Size in bytes (should be int?
    var fileType: String; // File extension, eg mp3
    var url: String?;
    
    init(fromJson: Dictionary<String, AnyObject>) {
        id = fromJson["_id"] as! String;
        name = fromJson["name"] as! String;
        artist = fromJson["artist"] as! String;
        length = fromJson["length"] as! Float;
        numberOfChunks = fromJson["numberOfChunks"] as! Int;
        fixedChunkSize = fromJson["fixedChunkSize"] as! Float;
        fileType = fromJson["fileType"] as! String;
    }
    
    var description: String {
        return "name: \(name) artist: \(artist) length: \(length) numberofchunks: \(numberOfChunks) fileType \(fileType)";
    }
}

struct FileChunk: CustomStringConvertible {
    var id: String;
    var fileId: String;
    var number: Int;
    
    var description: String {
        return "id: \(id) fileId: \(fileId) number: \(number)";
    }
}