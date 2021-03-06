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
    
    // GET
    
    func getSongs(completionBlock: SongArrayClosure) {
        Alamofire.request(.GET, URLStringWithExtension("songs/user/\(User.sharedInstance.id!)"))
            .responseJSON { response in                
                var songs : Array<Song> = Array<Song>();
                
                if let json = response.result.value {
                    
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
    
    func getSong(songId: String, completionBlock: SongClosure) {

    }
    
    // POST
    
    func signUpUser(username: String, password: String, completionBlock: UserDataClosure?) {
        let parameters = ["email" : username, "password" : password, "firstName" : "Dave", "lastName" : "Small"]
        Alamofire.request(.POST, URLStringWithExtension("user/signup"), parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                if let json = response.result.value {
                    completionBlock?(error: nil, user: UserData(fromJson: json as! Dictionary<String, AnyObject>));
                }
                else {
                    completionBlock?(error: response.result.error, user: nil)
                }
        }
    }
    
    func signInUser(username: String, password: String, completionBlock: UserDataClosure?) {
        let parameters = ["email" : username, "password" : password]
        Alamofire.request(.POST, URLStringWithExtension("user/signin"), parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                if let json = response.result.value {
                    completionBlock?(error: nil, user: UserData(fromJson: json as! Dictionary<String, AnyObject>));
                }
                else {
                    completionBlock?(error: response.result.error, user: nil)
                }
        }
    }
    
    // Utility
    
    func URLStringWithExtension(urlExtension: String) -> String {
        return "\(baseURL)/\(urlExtension)";
    }
    
}
