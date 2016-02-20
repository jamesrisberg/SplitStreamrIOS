//
//  RestNetworkAccessor.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import Alamofire

class RestNetworkAccessor: NSObject, NetworkingAccessor {
    
    let baseURL = "https:testurl.com";
    
    // GET
    
    func GetSongs(completionBlock: SongArrayClosure) {
        Alamofire.request(.GET, URLStringWithExtension("songs"))
            .responseJSON { response in
                // DEBUG: print(response.request)  // original URL request
                // DEBUG: print(response.response) // URL response
                // DEBUG: print(response.data)     // server data
                // DEBUG: print(response.result)   // result of response serialization
                
                var songs : Array<Song> = Array<Song>();
                
                if let json = response.result.value {
                    print(json);
                    
                    for jsonSong in json as! Array<Dictionary<String, AnyObject>> {
                        songs.append(Song(fromJson: jsonSong));
                    }
                    
                    completionBlock(error: nil, list: songs);
                }
                else {
                    completionBlock(error: response.result.error, list: songs);
                }
        }
    }
    
    func GetSong(songId: String, completionBlock: SongClosure) {
        
    }
    
    // POST
    
    // Utility
    
    func URLStringWithExtension(urlExtension: String) -> String {
        return "\(baseURL)/\(urlExtension)";
    }
    
}
