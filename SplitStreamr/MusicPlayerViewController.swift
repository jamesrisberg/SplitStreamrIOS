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
    let queuePlayer : AVQueuePlayer = AVQueuePlayer();
    var timer: NSTimer?;
    var playing = false;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        configureSubviews();
        
        manager.configureForPlayMode();
        manager.startBrowsing();
                
        SongManager.sharedInstance.onSongReadyToPlay = onSongReadyToPlay;
    }
    
    func configureSubviews() {
        titleLabel.text = "Selected Title";
        artistLabel.text = "Selected Artist";
        
        playButtonView.layer.cornerRadius = playButtonView.frame.size.width/2;
        playButtonView.layer.shadowOffset = CGSizeMake(0.0, 1.0)
        playButtonView.layer.shadowOpacity = 0.6
        playButtonView.layer.shadowRadius = 1.5
        
        timeLabel.font = UIFont.monospacedDigitSystemFontOfSize(35.0, weight: UIFontWeightThin)
        
        upperProgressView.progressTintColor = transparentOrange;
        upperProgressView.trackTintColor = blueLight1;
    }
    
    func onSongReadyToPlay(song: Song, data: NSData) {
        self.audioPlayer?.stop();
        audioPlayer = nil;
        do {
            titleLabel.text = song.name;
            artistLabel.text = song.artist;
            try self.audioPlayer = AVAudioPlayer(data: data);
            
            if let _ = self.audioPlayer {
                self.play();
            }
        } catch let error as NSError {
            debugLog("error instantiating audio player \(error.localizedDescription)");
        }
    }
    
    func queueChunkToPlay(song: Song, data: NSData) {
        let path = NSTemporaryDirectory().stringByAppendingString("tmp.mp3");
        data.writeToFile(path, atomically: true);
        let filePath = NSURL(fileURLWithPath: path);
        
        let item = AVPlayerItem(URL: filePath);
            
        queuePlayer.insertItem(item, afterItem: nil);
        
        if !playing {
            playing = true;
            queuePlayer.play()
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
        
        timer = NSTimer(timeInterval: 1.0, target: self, selector: "updateTime", userInfo: nil, repeats: true);
        
        if let _ = timer {
            NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes);
        }
    }
    
    func pause() {
        if let player = audioPlayer {
            player.pause()
            if let image = UIImage(named: "Play") {
                playPauseButton.setImage(image, forState: .Normal);
            }
        }
    }
    
    @IBAction func next() {
        self.songTable.playNextSong();
    }
    
    @IBAction func previous() {
        self.songTable.playPreviousSong();
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
        timer?.invalidate();
        audioPlayer = nil;
        SessionManager.sharedInstance.disconnectFromSession();
        
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}
