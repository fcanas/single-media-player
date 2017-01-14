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

let CMTimeValueKey = "CMTimeValueKey"
let CMTimeTimeScaleKey = "CMTimeTimeScaleKey"

class ViewController: UIViewController {

    let player = AVPlayer()
    let meidaAsset = AVAsset(url: Bundle.main.url(forResource: "Babies", withExtension: "m4v")!)
    var meidaItem :AVPlayerItem?
    
    var lastObservedTime :CMTime {
        set {
            guard newValue.isValid && newValue.isNumeric else {
                return
            }
            let value = NSNumber(value: newValue.value)
            let timeScale = NSNumber(value: newValue.timescale)
            let dict :NSDictionary = [ CMTimeValueKey : value, CMTimeTimeScaleKey : timeScale ]
            UserDefaults.standard.set(dict, forKey: lastObservedTimeKey)
        }
        get {
            guard let dict = UserDefaults.standard.value(forKey: lastObservedTimeKey) as? NSDictionary else {
                return kCMTimeZero
            }
            
            guard let value = (dict[CMTimeValueKey] as? NSNumber)?.int64Value,
                let timescale = (dict[CMTimeTimeScaleKey] as? NSNumber)?.int32Value else {
                    return kCMTimeZero
            }
            
            return CMTime(value: value, timescale: timescale)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(player, selector: #selector(AVPlayer.play), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveTime), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let volumeView = MPVolumeView(frame: .zero)
        view.addSubview(volumeView)
        volumeView.clipsToBounds = true
        volumeView.isUserInteractionEnabled = false
        
        let layer = AVPlayerLayer(player: player)
        layer.frame = self.view.layer.bounds
        view.layer.addSublayer(layer)
        
        meidaItem = AVPlayerItem(asset: meidaAsset)
        
        let assetDuration = meidaAsset.duration
        let endTime = assetDuration - CMTime(seconds: 0.5, preferredTimescale: assetDuration.timescale)
        
        player.replaceCurrentItem(with: meidaItem)
        
        player.addBoundaryTimeObserver(forTimes: [NSValue(time: endTime)], queue: .main) { [unowned self] in
            let strongSelf = self
            strongSelf.player.pause()
            strongSelf.player.seek(to: kCMTimeZero, completionHandler: { [unowned self] (completed) in
                let strongSelf = self
                if completed {
                    strongSelf.player.play()
                } else {
                    strongSelf.lastObservedTime = kCMTimeZero
                    exit(0)
                }
            })
        }
        
        player.seek(to: lastObservedTime)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
    
    func saveTime() {
        lastObservedTime = player.currentTime()
    }

}

