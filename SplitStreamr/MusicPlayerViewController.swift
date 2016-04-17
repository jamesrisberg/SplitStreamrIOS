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
    @IBOutlet weak var playButtonView: UIView!;
    @IBOutlet weak var playerView: UIView!;
    var upperProgressView: UIProgressView?;
    
    var songDrawer: SongDrawerView?;
    var drawerUp = false;
    
    let manager = SessionManager.sharedInstance;
    var timer: NSTimer?;
    var playing = false;
    
    var currentInputSongStream: NSInputStream?
    var currentOutputSongStream: NSOutputStream?
    
    var currentSongTime: Float = 0.0;
    var currentSongDuration: Float = 180.0;
    var currentSongMetadata: TDAudioMetaInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        configureSubviews();
        
        manager.configureForPlayMode();
        manager.startBrowsing();
        
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        let bufferSize: CFIndex = 128000;
        
        CFStreamCreateBoundPair(nil, &readStream, &writeStream, bufferSize);
        
        currentInputSongStream = readStream?.takeUnretainedValue();
        currentOutputSongStream = writeStream?.takeUnretainedValue();
        
        currentInputSongStream?.open();
        currentOutputSongStream?.open();

        SongManager.sharedInstance.queueChunkToPlay = queueChunkToPlay;
        SongManager.sharedInstance.downloadSongs();
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MusicPlayerViewController.songSelected), name: "SongSelected", object: nil)
    }
    
    func songSelected(notification: NSNotification) {
        if let info = notification.userInfo as? [String : String] {
            titleLabel.text = info["songName"]
            artistLabel.text = info["songArtist"]
            currentSongDuration = Float(info["songLength"]!)!
            
            currentSongMetadata = TDAudioMetaInfo();
            currentSongMetadata!.title = info["songName"];
            currentSongMetadata!.artist = info["songArtist"];
//            currentSongMetadata!.albumArtSmall = "http://www.some-address.com/track_id/low_res_image.png";
//            currentSongMetadata!.albumArtLarge = "http://www.some-address.com/track_id/high_res_image.png";
            currentSongMetadata!.duration = Float(info["songLength"]!)!;
        } else {
            debugLog("Song info not found!")
        }
    }
    
    func configureSubviews() {
        titleLabel.text = "Selected Title";
        artistLabel.text = "Selected Artist";
        
        playButtonView.layer.cornerRadius = playButtonView.frame.size.width/2;
        playButtonView.layer.shadowOffset = CGSizeMake(0.0, 1.0)
        playButtonView.layer.shadowOpacity = 0.6
        playButtonView.layer.shadowRadius = 1.5
        
        timeLabel.font = UIFont.monospacedDigitSystemFontOfSize(35.0, weight: UIFontWeightThin)
        
        var frame = self.view.frame
        upperProgressView = UIProgressView(frame: frame)
        
        if let view = upperProgressView {
            view.progressTintColor = transparentOrange;
            view.trackTintColor = blueLight1;
            self.view.addSubview(view)
            self.view.sendSubviewToBack(view)
        }
        
        songDrawer = SongDrawerView.instanceFromNib()
        frame.origin.y = (frame.size.height - 60)
        songDrawer?.frame = frame
        songDrawer?.bounds = self.view.bounds
        if let view = songDrawer {
            self.view.addSubview(view)
        }
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(MusicPlayerViewController.toggleSongDrawer))
        songDrawer?.upNextView.addGestureRecognizer(recognizer)
    }
    
    func toggleSongDrawer() {
        if drawerUp {
            drawerUp = false
            lowerDrawer()
        } else {
            drawerUp = true
            raiseDrawer()
        }
    }
    
    func raiseDrawer() {
        UIView.animateWithDuration(0.5) {
            var frame = self.view.frame
            frame.origin.y = 20
            self.songDrawer?.frame = frame
            self.playerView.alpha = 0.0
        }
    }
    
    func lowerDrawer() {
        UIView.animateWithDuration(0.5) {
            var frame = self.view.frame
            frame.origin.y = (frame.size.height - 60)
            self.songDrawer?.frame = frame
            self.playerView.alpha = 1.0
        }
    }
    
    func queueChunkToPlay(chunkNumber: Int, musicData: NSData) {
        var buffer = [UInt8](count: musicData.length, repeatedValue: 0);
        musicData.getBytes(&buffer, length: musicData.length);
        currentOutputSongStream?.write(&buffer, maxLength: musicData.length);
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
        TDAudioPlayer.sharedAudioPlayer().loadAudioFromStream(currentInputSongStream, withMetaData: currentSongMetadata);
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let image = UIImage(named: "Pause") {
                self.playPauseButton.setImage(image, forState: .Normal);
            }
        });
    }
    
    func pause() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let image = UIImage(named: "Play") {
                self.playPauseButton.setImage(image, forState: .Normal);
            }
        });
    }
    
    @IBAction func next() {
        self.songDrawer?.songTable.playNextSong();
    }
    
    @IBAction func previous() {
        self.songDrawer?.songTable.playPreviousSong();
    }
    
    func updateTime() {
//        self.currentSongTime += 1;
//
//        if let view = self.upperProgressView {
//            view.setProgress(self.currentSongTime/self.currentSongDuration, animated: true);
//        }
//        
//        let minutes = Int(self.currentSongTime) / 60
//        let seconds = Int(self.currentSongTime) % 60;
//        debugLog("\(currentSongTime) : \(minutes) : \(seconds)")
//
//        self.timeLabel.text = NSString(format: "%02d:%02d", minutes,seconds) as String
    }
    
    @IBAction func backToMenu() {
        timer?.invalidate();
        SessionManager.sharedInstance.disconnectFromSession();
        
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}
