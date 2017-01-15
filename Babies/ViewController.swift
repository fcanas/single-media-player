//
//  ViewController.swift
//  Babies
//
//  Created by Fabian Canas on 1/13/17.
//  Copyright © 2017 Fabián Cañas. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import MediaPlayer


let lastObservedTimeKey = "lastObservedTimeKey"

class ViewController: UIViewController {
    
    let player = AVPlayer()
    let mediaAsset = AVAsset(url: Bundle.main.url(forResource: "Media", withExtension: "m4v")!)
    var mediaItem :AVPlayerItem? {
        return AVPlayerItem(asset: mediaAsset)
    }
    
    /**
     The most recent playback location, persisted in NSUserDefaults
     
     Should be updated with the app is backgrounded. Should read and seek to
     time when appearing.
     */
    var lastObservedTime :CMTime {
        set {
            guard newValue.isValid && newValue.isNumeric else {
                return
            }
            UserDefaults.standard.set(newValue, forKey: lastObservedTimeKey)
        }
        get {
            guard let time = UserDefaults.standard.time(forKey: lastObservedTimeKey) else {
                return kCMTimeZero
            }
            return time
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Register for application fore/background notifications
        
        // Player should play when the app becomes active
        // When receiving this notification, we already have media loaded and
        // previously playing. So there is no need to seek since the playhead
        // will be at the right location.
        NotificationCenter.default.addObserver(player, selector: #selector(AVPlayer.play), name: .UIApplicationDidBecomeActive, object: nil)
        
        // When application is backgrounded, we should note the current time.
        // Playback will be paused automatically.
        NotificationCenter.default.addObserver(self, selector: #selector(saveTime), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        disableSystemVolumeHUD()
        
        setupPlayerLayer()
        
        player.replaceCurrentItem(with: mediaItem)
        
        setupReplayBehavior()
        
        player.seek(to: lastObservedTime)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
    
    func saveTime() {
        lastObservedTime = player.currentTime()
    }
    
    // MARK: - Convenience Procedures
    
    /// Build an invisible volume view to hide System volume HUD
    func disableSystemVolumeHUD() {
        let volumeView = MPVolumeView(frame: .zero) // Zero frame
        view.addSubview(volumeView)
        volumeView.clipsToBounds = true // Clipping to bounds ensure it's not visible
        volumeView.isUserInteractionEnabled = false // Still accepts taps and may show airplay prompt without this
    }
    
    /// Build an AVPlayer layer and add it to our view's layer tree so the
    /// player's video is visible.
    func setupPlayerLayer() {
        let layer = AVPlayerLayer(player: player)
        layer.frame = self.view.layer.bounds
        view.layer.addSublayer(layer)
    }
    
    /// Configure the player to replay when playback naturally proceeds to the
    /// end of the media.
    func setupReplayBehavior() {
        // When we play to the end:
        let assetDuration = mediaAsset.duration
        let endTime = assetDuration - CMTime(seconds: 0.5, preferredTimescale: assetDuration.timescale)
        player.addBoundaryTimeObserver(forTimes: [NSValue(time: endTime)], queue: .main) { [unowned self] in
            let strongSelf = self
            // Pause
            strongSelf.player.pause()
            // Seek to the beginning,
            strongSelf.player.seek(to: kCMTimeZero, completionHandler: { [unowned self] (completed) in
                let strongSelf = self
                if completed {
                    // then play
                    strongSelf.player.play()
                } else {
                    // or if seeking failed (more specifically, multiple seeks
                    // happened, we're likely in a weird state) just reset the
                    // last observed time to the beginning and exit.
                    strongSelf.lastObservedTime = kCMTimeZero
                    exit(0)
                }
            })
        }
        
    }
    
}

extension UserDefaults {
    func set(_ time: CMTime, forKey key: String) {
        set(time.dictionaryRepresentation, forKey: key)
    }
    
    func time(forKey key: String) -> CMTime? {
        return (value(forKey: key) as? NSDictionary).flatMap { CMTime(dictionaryRepresentation: $0) }
    }
}

extension CMTime {
    
    fileprivate static let valueKey = "value"
    fileprivate static let timescaleKey = "timescale"
    fileprivate static let flagsKey = "flags"
    fileprivate static let epochKey = "epoch"
    
    public var dictionaryRepresentation :NSDictionary {
        get {
            return [CMTime.valueKey     : NSNumber(value: value),
                    CMTime.timescaleKey : NSNumber(value: timescale),
                    CMTime.flagsKey     : NSNumber(value: flags.rawValue),
                    CMTime.epochKey     : NSNumber(value :epoch)
            ]
        }
    }
    
    init?(dictionaryRepresentation dict: NSDictionary) {
        guard
            let value     = (dict[CMTime.valueKey]     as? NSNumber)?.int64Value,
            let timescale = (dict[CMTime.timescaleKey] as? NSNumber)?.int32Value,
            let flags     = (dict[CMTime.flagsKey]     as? NSNumber).map({ CMTimeFlags(rawValue: $0.uint32Value) }),
            let epoch     = (dict[CMTime.epochKey]     as? NSNumber)?.int64Value
            else {
                return nil
        }
        self = CMTime(value: value, timescale: timescale, flags: flags, epoch: epoch)
    }
    
}

