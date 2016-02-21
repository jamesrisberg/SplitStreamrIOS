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
    var audioPlayer = AVAudioPlayer();
    var timer: NSTimer!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        configurePlayView();
        
        titleLabel.text = "Ultralight Beam";
        artistLabel.text = "Kanye West";
        
        let path = NSBundle.mainBundle().URLForResource(titleLabel.text!, withExtension: "mp3");
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOfURL: path!);
        } catch {
            print("error");
        }


        //manager.configureForPlayMode();
        //manager.startBrowsing();
                
        //SongManager.sharedInstance.onSongReadyToPlay = onSongReadyToPlay;
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
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            // TODO: tear down audio player
            audioPlayer.stop();

            // TODO: disconnect from all sessions
            SessionManager.sharedInstance.disconnectFromSession();
        }
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
        
        upperProgressView.setProgress(Float(audioPlayer.currentTime/audioPlayer.duration), animated: true);
        
        timeLabel.text = NSString(format: "%02d:%02d", minutes,seconds) as String
    }
    
    @IBAction func backToMenu() {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}
