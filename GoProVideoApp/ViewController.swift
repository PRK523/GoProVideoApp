//
//  ViewController.swift
//  GoProVideoApp
//
//  Created by Pranoti Kulkarni on 4/24/19.
//  Copyright © 2019 Pranoti Kulkarni. All rights reserved.
//


import UIKit
import ABVideoRangeSlider
import AVKit
import AVFoundation

class ViewController: UIViewController, ABVideoRangeSliderDelegate {
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    
    var start = 0.0;
    var end = 0.0;
    var progressTime = 0.0;
    var shouldUpdateProgressIndicator = true
    var isSeeking = false
    var timeObserver: AnyObject!
    
    
    @IBOutlet weak var pause: UIButton!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var videoScrubber: ABVideoRangeSlider!
    @IBOutlet weak var positionIndicatorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //used the same video as provided in the readMe file.
        guard let videoPath = Bundle.main.path(forResource: "example_scrubber", ofType:"mov") else {
            print("Video not found")
            return
        }
        
        player = AVPlayer(url: URL(fileURLWithPath: videoPath))
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        
        let timeInterval: CMTime = CMTimeMakeWithSeconds(0.01, preferredTimescale: 100)
        timeObserver = self.player.addPeriodicTimeObserver(forInterval: timeInterval,
                                                        
                        queue: DispatchQueue.main) { (elapsedTime: CMTime) -> Void in
                            self.observeTime(elapsedTime: elapsedTime) } as AnyObject?
        print(timeObserver ?? "")
}
    
    @IBAction func playTapped(_ sender: Any) {
        player.play()
        shouldUpdateProgressIndicator = true
        play.isEnabled = false
        pause.isEnabled = true
    }
    @IBAction func pauseTapped(_ sender: Any) {
        player.pause()
        play.isEnabled = true
        pause.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let videoPath = Bundle.main.path(forResource: "example_scrubber", ofType:"mov") else {
            print("Video not found")
            return
        }
        //used third party framework ABVideoRangeSlider to show the frames for video and scrubbing and seeking through the video frame.
        self.end = CMTimeGetSeconds((self.player.currentItem?.duration)!)

        videoScrubber.setVideoURL(videoURL: URL(fileURLWithPath: videoPath))
        videoScrubber.delegate = self

        videoView.layer.addSublayer(playerLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }
    
    private func observeTime(elapsedTime: CMTime) {
        let elapsedTime = CMTimeGetSeconds(elapsedTime)
        
        if (player.currentTime().seconds > self.end){
            player.pause()
            play.isEnabled = true
            pause.isEnabled = false
        }
        
        if self.shouldUpdateProgressIndicator{
            videoScrubber.updateProgressIndicator(seconds: elapsedTime)
        }
    }
    
    
    //ABVideoRangeSlider delegate methods
    func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64) {
        self.shouldUpdateProgressIndicator = false
        
        // Pause the player
        player.pause()
        play.isEnabled = true
        pause.isEnabled = false
        
        if self.progressTime != position {
            self.progressTime = position
            let timescale = self.player.currentItem?.asset.duration.timescale
            let time = CMTimeMakeWithSeconds(self.progressTime, preferredTimescale: timescale!)
            if !self.isSeeking{
                self.isSeeking = true
                player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero){_ in
                    self.isSeeking = false
                }
            }
        }
        //print(Double(position))
        //this label shows the current time stamp of the video when the progress indicator for the scrubber is slided.
        positionIndicatorLabel.text = "\(Double(position))"
    }
    
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
        
        self.end = endTime
        
        if startTime != self.start{
            self.start = startTime
            
            let timescale = self.player.currentItem?.asset.duration.timescale
            let time = CMTimeMakeWithSeconds(self.start, preferredTimescale: timescale!)
            if !self.isSeeking{
                self.isSeeking = true
                player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero){_ in
                    self.isSeeking = false
                }
            }
        }
    }
}

