//
//  NetworkFacade.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON

class NetworkFacade : NSObject {

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
        let sessionConnect = ["message" : "join session", "session" : sessionId];
        
        if let string = String(jsonObject: sessionConnect) {
            socket.writeString(string);
        }
    }
    
    func createNewSession() {
        let sessionCreate = ["message" : "create session"];
        
        if let string = String(jsonObject: sessionCreate) {
            socket.writeString(string);
        }
    }
    
    func startStreamingSong(songId: String) {
        let songStream = ["message" : "stream song", "song" : songId];
        
        if let string = String(jsonObject: songStream) {
            socket.writeString(string);
        }
    }
    
    // MARK:
    
    private func socketInit() {
        socket.delegate = self;
        socket.connect();
    }
}

// MARK: Web Socket Delegate

extension NetworkFacade : WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("socket connected: \(socket)");
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("socket disconnected \(socket), with error: \(error)");
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("socket recieved message: \(text)");
        
        if let dataFromString = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromString);
            
            if let sessionId = json["session"].string {
                print(sessionId);
                // TODO: Something with the session id
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("socket recieved data: \(data)");
        // TODO: Figure out what the data is, and call the appropriate delegate method
    }
}
