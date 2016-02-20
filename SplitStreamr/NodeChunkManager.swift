//
//  NodeChunkManager.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class NodeChunkManager: NSObject {
    
    var sessionId: String!;
    var playerPeer: MCPeerID!;
    
    override init() {
        super.init();
    }
    
    convenience init(playerPeer: MCPeerID) {
        self.init();
        self.playerPeer = playerPeer;
    }
    
    func joinSession(sessionId: String) {
        self.sessionId = sessionId;
    }
}

extension NodeChunkManager : NetworkFacadeDelegate {
    func musicPieceReceived(songId: String, chunkNumber: Int, musicData: NSData) {
        do {
            try SessionManager.sharedInstance.session.sendData(musicData, toPeers: [playerPeer], withMode: .Reliable);
        } catch {
            print("Error sending chunk");
        }
    }
    
    func sessionIdReceived(sessionId: String) {
        
    }
    
    func errorRecieved(error: NSError) {
        print(error.debugDescription);
    }
    
    func didEstablishConnection() {
        SessionManager.sharedInstance.connectToSession();
    }
}
