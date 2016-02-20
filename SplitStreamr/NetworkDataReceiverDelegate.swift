//
//  NetworkDataReceiverDelegate.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation

protocol NetworkDataReceiverDelegate {
    func musicPieceReceived(musicData: NSData);
    func sessionIdReceived(sessionId: String);
    
}
