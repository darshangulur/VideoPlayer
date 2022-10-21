//
//  VideoPlayerView.swift
//  VideoPlayer
//
//  Created by Darshan Srinivasa on 10/20/22.
//

import UIKit
import AVFoundation

final class VideoPlayerView: UIView {
    private var playerItemContext = 0
    private var playerItem: AVPlayerItem?
    
    private lazy var avPlayerLayer = AVPlayerLayer()
    private let url: URL
    
    // MARK: Initializers
    init(url: URL) {
        self.url = url
        super.init(frame: .zero)
        
        layer.addSublayer(avPlayerLayer)
        
        asset(
            withURL: url
        ) { [weak self] asset in
            guard let asset = asset else {
                print("Asset is nil.")
                return
            }
            
            self?.loadAVPlayerItem(withAsset: asset)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        playerItem?.removeObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status)
        )
    }
    
    // MARK: Overrides
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avPlayerLayer.frame = self.bounds
    }
    
    // MARK: Private vars
    private func asset(withURL url: URL, onLoading: @escaping (AVAsset?) -> Void) {
        let asset = AVAsset(url: url)
        let playableKey = "playable"
        asset.loadValuesAsynchronously(
            forKeys: [playableKey],
            completionHandler: {
                var error: NSError?
                let status = asset.statusOfValue(
                    forKey: playableKey,
                    error: &error
                )
                
                switch status {
                case .loaded:
                    onLoading(asset)
                    
                case .failed:
                    onLoading(nil)
                    
                default:
                    break
                }
            }
        )
    }
    
    // MARK: Private methods
    private func loadAVPlayerItem(withAsset asset: AVAsset) {
        playerItem = AVPlayerItem(asset: asset)
        playerItem?.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: [.old, .new],
            context: &playerItemContext
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.avPlayerLayer.player = AVPlayer(playerItem: self.playerItem)
        }
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(
                forKeyPath: keyPath,
                of: object,
                change: change,
                context: context
            )
            return
        }
        
        guard keyPath == #keyPath(AVPlayerItem.status) else {
            return
        }
        
        let status: AVPlayerItem.Status
        if let statusValue = change?[.newKey] as? NSNumber,
            let newStatus = AVPlayerItem.Status(rawValue: statusValue.intValue) {
            status = newStatus
        } else {
            status = .unknown
        }
        
        switch status {
        case .readyToPlay:
            self.avPlayerLayer.player?.play()
            print("Playback Started.")
            
        case .failed:
            print("Playback failed.")
            
        default:
            break
        }
    }
}
