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
    
    private let serviceType = "splitStreamr";
    
    let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name);
    private let serviceAdvertiser : MCNearbyServiceAdvertiser;
    private let serviceBrowser : MCNearbyServiceBrowser;
    
    var peers: [MCPeerID] = [];
    
    var streamDelegates: [MeshStreamDelegate] = [];
    
    var playerPeer: MCPeerID!;
    var playerChunkManager: PlayerChunkManager!;
    var nodeChunkManager: NodeChunkManager!;
    var networkFacade: NetworkFacade!;
    
    var networkSessionId: String!;
    
    let serialQueue = dispatch_queue_create("com.SerialQueue", DISPATCH_QUEUE_SERIAL);
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .None);
        session.delegate = self;
        return session;
    }()
    
    static let sharedInstance = SessionManager();
    
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
        networkFacade = NetworkFacade(delegate: playerChunkManager);
    }
    
    func configureForNodeMode(playerPeer: MCPeerID) {
        playerChunkManager = nil;
        self.playerPeer = playerPeer;
        nodeChunkManager = NodeChunkManager(playerPeer: playerPeer);
        networkFacade = NetworkFacade(delegate: nodeChunkManager);
    }
    
    func createNewSession() {
        networkFacade.createNewSession();
    }
    
    func connectToSession() {
        networkFacade.connectToSession(networkSessionId);
    }
    
    func setSessionId(id: String) {
        networkSessionId = id;
    }
    
    func streamSong(song: Song) {
        playerChunkManager.prepareForSong(song);
        networkFacade.startStreamingSong(song.id);
    }
    
    func chunkFinishedStreaming(chunkData: NSMutableData, delegate: MeshStreamDelegate) {
        print("Stream Finished");
    
        streamDelegates.removeAtIndex(streamDelegates.indexOf(delegate)!);
        
        var error : NSError?
        let json = JSON(data: chunkData, options: NSJSONReadingOptions(rawValue:0), error: &error);
        
        if let items = json.array {
            for item in items {
                if let chunkNumber = item["chunkNumber"].string {
                    if let musicString = item["musicData"].string {
                        let musicData = NSData(base64EncodedString: musicString, options: NSDataBase64DecodingOptions(rawValue:0));
                        self.playerChunkManager.addNodeChunk(Int(chunkNumber)!, musicData: musicData!);
                    } else {
                        print("Error getting chunk data: \(json["musicData"].string)");
                    }
                } else {
                    print("Error getting chunk numba: \(json["chunkNumber"].string)");
                }
            }
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
        self.serviceBrowser.invitePeer(peers[index], toSession: self.session, withContext: networkSessionId.dataUsingEncoding(NSUTF8StringEncoding), timeout: 10);
    }
    
    func invitePeer(peer: MCPeerID) {
        self.serviceBrowser.invitePeer(peer, toSession: self.session, withContext: networkSessionId.dataUsingEncoding(NSUTF8StringEncoding), timeout: 10);
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
        self.session.disconnect();
        self.networkFacade.disconnectFromCurrentSession();
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
        self.setSessionId(String.init(data: context!, encoding: NSUTF8StringEncoding)!);
        self.configureForNodeMode(peerID);
        invitationHandler(true, self.session);
        NSNotificationCenter.defaultCenter().postNotificationName("InvitationAccepted", object: nil);
    }
}

extension SessionManager : MCNearbyServiceBrowserDelegate {
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)");
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)");
        self.peers.append(peerID);
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
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Stream recieved");
        self.streamDelegates.append(MeshStreamDelegate(stream: stream));
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        NSLog("%@", "didFinishReceivingResourceWithName");
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        NSLog("%@", "didStartReceivingResourceWithName");
    }
}
