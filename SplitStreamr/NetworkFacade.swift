//
//  NetworkFacade.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import Starscream

class NetworkFacade : NSObject, WebSocketDelegate {

    let restDataAccessor : NetworkingAccessor;
    
    let socketURL = "ws://echo.websocket.org";
    let socket : WebSocket;
    
    override init() {
        // TODO: pass data accessor and socket to use in the init method
        restDataAccessor = RestNetworkAccessor();
        socket = WebSocket(url: NSURL(string: socketURL)!);
        
        super.init();
        socketInit();
    }
    
    func getSongs(completionBlock: SongArrayClosure) {
        restDataAccessor.getSongs(completionBlock);
    }
    
    func connectToSession(sessionId: String) {
        socket.writeString("connect to session: \(sessionId)");
    }
    
    func createNewSession() {
        socket.writeString("new session");
    }
    
    // MARK:
    
    func socketInit() {
        socket.delegate = self;
        socket.connect();
    }
    
    // MARK: Socket Delegate
    
    func websocketDidConnect(socket: WebSocket) {
        print("socket connected");
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("socket disconnected with error: \(error)");
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("socket recieved message: \(text)");
        // TODO: Figure out what the message is, and call the appropriate delegate method
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("socket recieved data: \(data)");
        // TODO: Figure out what the data is, and call the appropriate delegate method
    }
    
}
