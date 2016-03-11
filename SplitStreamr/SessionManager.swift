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

class SessionManager: NSObject {
    
    let serviceType = "splitStreamr";
    
    let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name);
    
    let serviceAdvertiser : MCNearbyServiceAdvertiser;
    let serviceBrowser : MCNearbyServiceBrowser;
    
    var peers: [MCPeerID] = [];
    
    var playerPeer: MCPeerID?;
    var playerChunkManager: PlayerChunkManager?;
    var nodeChunkManager: NodeChunkManager?;
    var networkFacade: NetworkFacade?;
    var currentStreamingSongId: String?;
    
    var networkSessionId: String?;
    
    let serialQueue = dispatch_queue_create("com.SerialQueue", DISPATCH_QUEUE_SERIAL);
    
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
        nodeChunkManager = nil;
        playerChunkManager = PlayerChunkManager();
        
        if let _ = playerChunkManager {
            networkFacade = NetworkFacade(delegate: playerChunkManager!);
        }
    }
    
    func configureForNodeMode(playerPeer: MCPeerID) {
        playerChunkManager = nil;
        self.playerPeer = playerPeer;
        nodeChunkManager = NodeChunkManager(playerPeer: playerPeer);
        
        if let _ = nodeChunkManager {
            networkFacade = NetworkFacade(delegate: nodeChunkManager!);
        }
    }
    
    func createNewSession() {
        if let _ = networkFacade {
            networkFacade!.createNewSession();
        } else {
            
        }
    }
    
    func connectToSession() {
        if let _ = networkFacade {
            if let _ = networkSessionId {
                networkFacade!.connectToSession(networkSessionId!);
            }
        } else {
            
        }
    }
    
    func setSessionId(id: String) {
        networkSessionId = id;
    }
    
    func streamSong(song: Song) {
        if let _ = networkFacade {
            do {
                let json = [ "type" : "songID", "songID" : song.id];

                if let jsonString = String.stringFromJson(json) {
                    try session.sendData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, toPeers: peers, withMode: .Reliable);
                }
            } catch {
                print("error sending song ID to nodes");
            }
            
            if let _ = playerChunkManager {
                playerChunkManager!.prepareForSong(song);
            }
            
            networkFacade!.startStreamingSong(song.id);
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
            self.serviceBrowser.invitePeer(peers[index], toSession: self.session, withContext: networkSessionId!.dataUsingEncoding(NSUTF8StringEncoding), timeout: 10);
        }
    }
    
    func invitePeer(peer: MCPeerID) {
        if let _ = networkSessionId {
            self.serviceBrowser.invitePeer(peer, toSession: self.session, withContext: networkSessionId!.dataUsingEncoding(NSUTF8StringEncoding), timeout: 10);
        }
    }
    
    func connectedPeerCount() -> Int {
        return session.connectedPeers.count;
    }
    
    func peerCount() -> Int {
        return peers.count;
    }
    
    func peerNameAtIndex(index: Int) -> MCPeerID {
        return peers[index];
    }
    
    func disconnectFromSession() {
        if let _ = networkFacade {
            self.session.disconnect();
            networkFacade!.disconnectFromCurrentSession();
        }
    }
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
            case .NotConnected: return "NotConnected"
            case .Connecting: return "Connecting"
            case .Connected: return "Connected"
            default: return "Unknown"
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
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)");
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)");
        self.peers.append(peerID); // TODO: Wati until peer accepts invite to add to list
        self.invitePeer(peerID);
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)");
        self.peers.removeAtIndex(self.peers.indexOf(peerID)!);
    }
}

extension SessionManager : MCSessionDelegate {
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())");
        
        if (state == .NotConnected && peerID == myPeerId) {
            NSNotificationCenter.defaultCenter().postNotificationName("DidDisconnectFromSession", object: nil);
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        let json = JSON.parse(String(data: data, encoding: NSUTF8StringEncoding)!);
        
        if json["type"].stringValue == "songID" {
            NSNotificationCenter.defaultCenter().postNotificationName("SongStreaming", object: self, userInfo: ["songId" : json["songID"].stringValue]);
        } else {
            let chunkNumber = json["chunkNumber"].stringValue;
            let songID = json["songId"].stringValue;
            
            if json["type"].stringValue == "readyToSendStream" {
                debugLog("readyToSendStream");
                playerChunkManager!.prepareForStream(peerID);
            } else if json["type"].stringValue == "readyToRecieveStream" {
                debugLog("readyToRecieveStream");
                nodeChunkManager!.setupStreamWithPlayer(songID);
            } else if json["type"].stringValue == "didRecieveStream" {
                debugLog("didRecieveStream");
                nodeChunkManager!.preparePlayerForChunk();
            } else if json["type"].stringValue == "readyToSendChunk" {
                debugLog("readyToSendChunk");
                playerChunkManager!.prepareForChunk(chunkNumber, chunkSize: json["chunkSize"].stringValue, songId: songID, fromPeer: peerID);
            } else if json["type"].stringValue == "readyToRecieveChunk" {
                debugLog("readyToRecieveChunk");
                nodeChunkManager!.sendChunk(chunkNumber, songId: songID);
            } else if json["type"].stringValue == "didRecieveChunk" {
                debugLog("didRecieveChunk");
                nodeChunkManager!.preparePlayerForChunk();
            } else if json["type"].stringValue == "allChunksDone" {
                debugLog("allChunksDone");
                nodeChunkManager!.allChunksDone();
            }
        }
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        debugLog("Player received stream");
        playerChunkManager?.attachStream(peerID, stream: stream);
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        NSLog("%@", "didFinishReceivingResourceWithName");
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        NSLog("%@", "didStartReceivingResourceWithName");
    }
}
