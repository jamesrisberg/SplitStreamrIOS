//
//  MusicPlayerViewController.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit
import AVFoundation

class MusicPlayerViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!;
    @IBOutlet weak var artistLabel: UILabel!;
    @IBOutlet weak var timeLabel: UILabel!;
    @IBOutlet weak var playPauseButton: UIButton!;
    @IBOutlet weak var songTable: SongTableView!;
    
    let manager = SessionManager.sharedInstance;
    var audioPlayer = AVAudioPlayer();
    var timer: NSTimer!;
    
    override func viewDidLoad() {
        super.viewDidLoad();

        manager.configureForPlayMode();
        manager.startBrowsing();
                
        SongManager.sharedInstance.onSongReadyToPlay = onSongReadyToPlay;
    }
    
    func onSongReadyToPlay(song: Song, data: NSData) {
        do {
            try self.audioPlayer = AVAudioPlayer(data: data);
            
            titleLabel.text = song.name;
            artistLabel.text = song.artist;
            
            if !self.audioPlayer.playing {
                self.play();
            }
        } catch {
            print("error instantiating audio player");
        }
    }
    
    @IBAction func playOrPause() {
        if self.audioPlayer.playing {
            pause();
        } else {
            play();
        }
    }
    
    func play() {
        audioPlayer.play();
        
        if let image = UIImage(named: "Pause") {
            playPauseButton.setImage(image, forState: .Normal);
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateTime", userInfo: nil, repeats: true);
    }
    
    func pause() {
        audioPlayer.pause()
        
        if let image = UIImage(named: "Play") {
            playPauseButton.setImage(image, forState: .Normal);
        }
    }
    
    func updateTime() {
        let currentTime = Int(audioPlayer.currentTime)
        let minutes = currentTime/60
        let seconds = currentTime - minutes * 60
        
        timeLabel.text = NSString(format: "%02d:%02d", minutes,seconds) as String
    }
}
