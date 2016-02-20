//
//  NetworkingAccessor.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

protocol NetworkingAccessor {
    
    // GET
    func GetSongs(completionBlock: SongArrayClosure);
    func GetSong(songId: String, completionBlock: SongClosure);
    
    // POST
    
}
