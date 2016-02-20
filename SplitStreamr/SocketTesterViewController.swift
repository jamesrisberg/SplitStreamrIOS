//
//  SocketTesterViewController.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class SocketTesterViewController: UIViewController {

    @IBOutlet weak var songIdTextField: UITextField!
    @IBOutlet weak var sessionIdTextField: UITextField!
    
    var networkFacade : NetworkFacade?;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        networkFacade = NetworkFacade(delegate: self);
    }
    
    @IBAction func createSession(sender: AnyObject) {
        networkFacade?.createNewSession();
    }
    
    @IBAction func joinSession(sender: AnyObject) {
        networkFacade?.connectToSession(sessionIdTextField.text!);
    }
    
    @IBAction func requestSong(sender: AnyObject) {
        networkFacade?.startStreamingSong(songIdTextField.text!);
    }
}

extension SocketTesterViewController : NetworkFacadeDelegate {
    func musicPieceReceived(chunkNumber: Int, musicData: NSData) {
        
    }
    
    func sessionIdReceived(sessionId: String) {
        self.sessionIdTextField.text = sessionId;
    }
    
    func errorRecieved(error: NSError) {
        print("\(error)");
    }
    
    func didEstablishConnection() {
        
    }
}
