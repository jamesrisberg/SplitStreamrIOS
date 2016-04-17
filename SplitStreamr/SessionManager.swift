//
//  MCSessionManager.swift
//  SplitStreamr
//
//  Created by James on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import SwiftyJSON

protocol ChunkManager {
    func handleHandshakingMessage(json: JSON, peer: MCPeerID);
}

class SessionManager: NSObject {
    
    let serviceType = "splitStreamr";
    
    let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name);
    
    let serviceAdvertiser : MCNearbyServiceAdvertiser;
    let serviceBrowser : MCNearbyServiceBrowser;
    
    var playerPeer: MCPeerID?;
    
    var chunkManager: ChunkManager?;
    var networkFacade: NetworkFacade?;
    var currentStreamingSongId: String?;
    
    var networkSessionId: String?;
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .None);
        session.delegate = self;
        return session;
    }()
    
    static let sharedInstance : SessionManager = SessionManager();
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType);
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType);
        
        super.init();
        
        self.serviceAdvertiser.delegate = self;
        self.serviceBrowser.delegate = self;
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer();
        self.serviceBrowser.stopBrowsingForPeers();
    }
    
    // MARK: Network Session Management
    
    func configureForPlayMode() {
        chunkManager = PlayerChunkManager();
        initNetworkFacade();
    }
    
    func configureForNodeMode(playerPeer: MCPeerID) {
        self.playerPeer = playerPeer;
        chunkManager = NodeChunkManager(playerPeer: playerPeer);
        initNetworkFacade()
    }
    
    func initNetworkFacade() {
        if let _ = chunkManager {
            if chunkManager is NetworkFacadeDelegate {
                networkFacade = NetworkFacade(delegate: chunkManager as! NetworkFacadeDelegate);
            } else {
                debugLog("ChunkManager isn't a NetworkFacadeDelegate");
            }
        } else {
            debugLog("ChunkManager doesn't exist");
        }
    }
    
    func createNewSession() {
        if let _ = networkFacade {
            networkFacade!.createNewSession();
        } else {
            debugLog("NetworkFacade doesn't exist");
        }
    }
    
    func connectToSession() {
        if let _ = networkFacade {
            if let _ = networkSessionId {
                networkFacade!.connectToSession(networkSessionId!);
            } else {
                debugLog("NetworkSessionId doesn't exist");
            }
        } else {
            debugLog("NetworkFacade doesn't exist");
        }
    }
    
    func setSessionId(id: String) {
        networkSessionId = id;
    }
    
    func sendStreamSongToNodes(song: Song) {
        if let _ = networkFacade {
            let json = ["message": "songID", "songID": song.id];
            let jsonString = "\(String.stringFromJson(json)!)";
            
            let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding);
            do {
                try session.sendData(data!, toPeers: session.connectedPeers, withMode: .Reliable);
            } catch {
                debugLog("Error sending song ID to nodes");
            }
            
            if let _ = chunkManager {
                chunkManager?.handleHandshakingMessage(JSON(data: data!), peer: myPeerId);
            } else {
                debugLog("ChunkManager doesn't exist");
            }
            
            networkFacade!.startStreamingSong(song.id);
        } else {
            debugLog("NetworkFacade doesn't exist");
        }
    }
    
    func sendSongFinishedToNodes() {
        if let _ = networkFacade {
            let json = ["message": "allChunksDone"];
            let jsonString = "\(String.stringFromJson(json)!)";
            
            let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding);
            do {
                try session.sendData(data!, toPeers: session.connectedPeers, withMode: .Reliable);
            } catch {
                debugLog("Error sending allChunksDone to nodes");
            }
        } else {
            debugLog("NetworkFacade doesn't exist");
        }
    }
    
    // MARK: Multipeer Session Management
    
    func startAdvertising() {
        self.serviceAdvertiser.startAdvertisingPeer();
    }
    
    func stopAdvertising() {
        self.serviceAdvertiser.stopAdvertisingPeer();
    }
    
    func startBrowsing() {
        self.serviceBrowser.startBrowsingForPeers();
    }
    
    func stopBrowsing() {
        self.serviceBrowser.startBrowsingForPeers();
    }
    
    func invitePeerAtIndex(index: Int) {
        if let _ = networkSessionId {
            self.serviceBrowser.invitePeer(session.connectedPeers[index], toSession: self.session, withContext: networkSessionId!.dataUsingEncoding(NSUTF8StringEncoding), timeout: 10);
        } else {
            debugLog("networkSessionId doesn't exist");
        }
    }
    
    func invitePeer(peer: MCPeerID) {
        if let _ = networkSessionId {
            self.serviceBrowser.invitePeer(peer, toSession: self.session, withContext: networkSessionId!.dataUsingEncoding(NSUTF8StringEncoding), timeout: 10);
        } else {
            debugLog("networkSessionId doesn't exist");
        }
    }
    
    func connectedPeerCount() -> Int {
        return session.connectedPeers.count;
    }
    
    func peerCount() -> Int {
        return session.connectedPeers.count;
    }
    
    func peerNameAtIndex(index: Int) -> MCPeerID {
        return session.connectedPeers[index];
    }
    
    func disconnectFromSession() {
        if let _ = networkFacade {
            self.session.disconnect();
            networkFacade!.disconnectFromCurrentSession();
        }
    }
    
    // MARK: Data Helper Methods
    
    func sendSimpleJSONMessage(message: String, toPeer peer: MCPeerID) {
        debugLog("\(myPeerId.displayName) sending \(message) to \(peer.displayName)");
        let messageData = ["message" : message];
        let jsonString = "\(String.stringFromJson(messageData)!)";
        sendJSONString(jsonString, toPeer: peer);
    }
    
    func sendJSONString(jsonString: String, toPeer peer: MCPeerID) {
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                try session.sendData(data, toPeers: [peer], withMode: .Reliable);
            } catch {
                debugLog("Error sending \(jsonString) from \(myPeerId.displayName) to \(peer.displayName)");
            }
        } else {
            debugLog("Error building \(jsonString) from \(myPeerId.displayName) to \(peer.displayName)");
        }
    }
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
            case .NotConnected: return "NotConnected"
            case .Connecting: return "Connecting"
            case .Connected: return "Connected"
        }
    }
}

extension SessionManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)");
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        if let _ = context {
            self.setSessionId(String.init(data: context!, encoding: NSUTF8StringEncoding)!);
            self.configureForNodeMode(peerID);
            invitationHandler(true, session);
            NSNotificationCenter.defaultCenter().postNotificationName("InvitationAccepted", object: nil);
        }
    }
}

extension SessionManager : MCNearbyServiceBrowserDelegate {
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        debugLog("didNotStartBrowsingForPeers: \(error)");
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        debugLog("foundPeer: \(peerID)");
        self.invitePeer(peerID);
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        debugLog("lostPeer: \(peerID)");
    }
}

extension SessionManager : MCSessionDelegate {
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        debugLog("peer \(peerID) didChangeState: \(state.stringValue())");
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peer: MCPeerID) {
        let json = JSON(data: data);
        
        if json["message"].stringValue == "songID" {
            NSNotificationCenter.defaultCenter().postNotificationName("SongStreaming", object: self, userInfo: ["songId" : json["songID"].stringValue]);
        } else {
            if let manager = chunkManager {
                debugLog("\(myPeerId.displayName) received \(json["message"].stringValue) from \(peer.displayName)");
                manager.handleHandshakingMessage(json, peer: peer);
            } else {
                debugLog("ChunkManager doesn't exist");
            }
        }
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peer: MCPeerID) {
        if let manager = chunkManager as? PlayerChunkManager {
            debugLog("\(myPeerId.displayName) received stream from \(peer.displayName)");
            manager.attachStream(stream, fromPeer: peer);
        } else {
            debugLog("NodeChunkManager on peer \(myPeerId.displayName) received a stream from peer \(peer.displayName)");
        }
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        debugLog("didFinishReceivingResourceWithName");
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        debugLog("didStartReceivingResourceWithName");
    }
}
