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
    var queuePlayer : AVQueuePlayer? = AVQueuePlayer();
    var queuePlayerTimeObserver: AnyObject?;
    var timer: NSTimer?;
    var playing = false;
    
    var currentSongTime = 0;
    var currentSongDuration = 180;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        configureSubviews();
        
        manager.configureForPlayMode();
        manager.startBrowsing();
                
        SongManager.sharedInstance.queueChunkToPlay = queueChunkToPlay;
        
        queuePlayerTimeObserver = queuePlayer?.addPeriodicTimeObserverForInterval(CMTimeMake(1,1), queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), usingBlock: { (time) -> Void in
            self.updateTime();
        });
        
        queuePlayer?.actionAtItemEnd = .Advance;
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
    
    func queueChunkToPlay(chunkNumber: Int, data: NSData) {
        let path = NSTemporaryDirectory().stringByAppendingString("\(chunkNumber).mp3");
        data.writeToFile(path, atomically: true);
        let filePath = NSURL(fileURLWithPath: path);
        
        let item = AVPlayerItem(URL: filePath);
        
        if queuePlayer?.canInsertItem(item, afterItem: nil) == true {
            queuePlayer?.insertItem(item, afterItem: nil);
        }
        
        print(queuePlayer?.items());
        
        if !playing {
            playing = true;
            self.play();
        }
    }
    
    @IBAction func playOrPause() {
        if playing {
            playing = false;
            self.pause();
        } else {
            playing = true;
            self.play();
        }
    }
    
    func play() {
        queuePlayer?.play();
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let image = UIImage(named: "Pause") {
                self.playPauseButton.setImage(image, forState: .Normal);
            }
        });
    }
    
    func pause() {
        queuePlayer?.pause();
        timer?.invalidate();
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let image = UIImage(named: "Play") {
                self.playPauseButton.setImage(image, forState: .Normal);
            }
        });
    }
    
    @IBAction func next() {
        self.songTable.playNextSong();
    }
    
    @IBAction func previous() {
        self.songTable.playPreviousSong();
    }
    
    func updateTime() {
//        self.currentSongTime += 1;
//
//        self.upperProgressView.setProgress(Float(self.currentSongTime/self.currentSongDuration), animated: true);
//        
//        let minutes = self.currentSongTime / 60
//        let seconds = self.currentSongTime % 60;
//
//        self.timeLabel.text = NSString(format: "%02d:%02d", minutes,seconds) as String
    }
    
    @IBAction func backToMenu() {
        queuePlayer?.pause();
        queuePlayer?.removeAllItems();
        if let observer = queuePlayerTimeObserver {
            queuePlayer?.removeTimeObserver(observer);
        }
        timer?.invalidate();
        queuePlayer = nil;
        SessionManager.sharedInstance.disconnectFromSession();
        
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}
