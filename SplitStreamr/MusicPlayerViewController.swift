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
    @IBOutlet weak var playButtonView: UIView!;
    @IBOutlet weak var upperProgressView: UIProgressView!;
    
    let manager = SessionManager.sharedInstance;
    var audioPlayer : AVAudioPlayer?;
    var timer: NSTimer!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        configurePlayView();
        
        titleLabel.text = "Selected Title";
        artistLabel.text = "Selected Artist";
        
        manager.configureForPlayMode();
        manager.startBrowsing();
                
        SongManager.sharedInstance.onSongReadyToPlay = onSongReadyToPlay;
    }
    
    func configurePlayView() {
        playButtonView.layer.cornerRadius = playButtonView.frame.size.width/2;
        playButtonView.layer.shadowOffset = CGSizeMake(0.0, 1.0)
        playButtonView.layer.shadowOpacity = 0.6
        playButtonView.layer.shadowRadius = 1.5
        
        timeLabel.font = UIFont.monospacedDigitSystemFontOfSize(35.0, weight: UIFontWeightThin)
        
        upperProgressView.progressTintColor = UIColor.init(red: 236/255.0, green: 107/255.0, blue: 14/255.0, alpha: 0.5);
        upperProgressView.trackTintColor = UIColor(hexString: "65A5D1");
    }
    
    func onSongReadyToPlay(song: Song, data: NSData) {
        self.audioPlayer?.stop();
        audioPlayer = nil;
        do {
            titleLabel.text = song.name;
            artistLabel.text = song.artist;
            try self.audioPlayer = AVAudioPlayer(data: data);
            
            if let player = self.audioPlayer {
                self.play();
            }
        } catch let error as NSError {
            print("error instantiating audio player \(error.localizedDescription)");
        }
    }
    
    @IBAction func playOrPause() {
        if let player = self.audioPlayer {
            if player.playing {
                self.pause();
            }
            else {
                self.play();
            }
        }
    }
    
    func play() {
        audioPlayer?.play();
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let image = UIImage(named: "Pause") {
                self.playPauseButton.setImage(image, forState: .Normal);
            }
        });
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateTime", userInfo: nil, repeats: true);
    }
    
    func pause() {
        if let player = audioPlayer {
            player.pause()
            if let image = UIImage(named: "Play") {
                playPauseButton.setImage(image, forState: .Normal);
            }
            
        }
    }
    
    func next() {
        self.songTable.playNextSong();
    }
    
    func previous() {
        self.songTable.playNextSong();
    }
    
    func updateTime() {
        let currentTime = Int(audioPlayer!.currentTime)
        let minutes = currentTime/60
        let seconds = currentTime - minutes * 60
        
        upperProgressView.setProgress(Float(audioPlayer!.currentTime/audioPlayer!.duration), animated: true);
        
        timeLabel.text = NSString(format: "%02d:%02d", minutes,seconds) as String
    }
    
    @IBAction func backToMenu() {
        audioPlayer?.stop();
        timer.invalidate();
        audioPlayer = nil;
        SessionManager.sharedInstance.disconnectFromSession();
        
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}
