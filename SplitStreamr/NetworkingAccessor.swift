//
//  NetworkingAccessor.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

protocol NetworkingAccessor {
    
    // GET
    func getSongs(completionBlock: SongArrayClosure);
    func getSong(songId: String, completionBlock: SongClosure);
    
    // POST
    
}
