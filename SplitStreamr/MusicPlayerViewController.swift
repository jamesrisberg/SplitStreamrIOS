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
    
    var audioPlayer = AVAudioPlayer();
    var timer: NSTimer!;
    var playing = false;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        titleLabel.text = "Ultralight Beam";
        artistLabel.text = "Kanye West";
        
        let path = NSBundle.mainBundle().URLForResource(titleLabel.text!, withExtension: "mp3");
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOfURL: path!);
        } catch {
            print("error");
        }
        
        songTable.getSongs();
    }
    
    @IBAction func playOrPause() {
        if playing {
            pause();
        } else {
            play();
        }
    }
    
    func play() {
        audioPlayer.play();
        playing = true;
        
        if let image = UIImage(named: "Pause") {
            playPauseButton.setImage(image, forState: .Normal);
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateTime", userInfo: nil, repeats: true);
    }
    
    func pause() {
        audioPlayer.pause()
        playing = false;
        
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
