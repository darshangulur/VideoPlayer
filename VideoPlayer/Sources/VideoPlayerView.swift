//
//  VideoPlayerView.swift
//  VideoPlayer
//
//  Created by Darshan Srinivasa on 10/20/22.
//

import UIKit
import AVFoundation

///  A ``UIView`` to present video content.
final class VideoPlayerView: UIView {
    private enum Constants {
        static let statusKeyPath = #keyPath(AVPlayerItem.status)
    }
    
    private var playerItemContext = 0
    private var playerItem: AVPlayerItem?
    
    private var endTimeObserver: NSObjectProtocol?
    private var periodicTimeObserver: Any?
    
    private lazy var avPlayerLayer = AVPlayerLayer()
    private let url: URL
    
    // MARK: Initializers
    /// Initializes a ``VideoPlayerView``.
    ///  - Parameters:
    ///    - url: A ``URL`` of the video content resource to be played.
    init(url: URL) {
        self.url = url
        
        super.init(frame: .zero)
        layer.addSublayer(avPlayerLayer)
        
        setUpObservers()
        
        loadContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        playerItem?.removeObserver(
            self,
            forKeyPath: Constants.statusKeyPath
        )
        
        [endTimeObserver, periodicTimeObserver].forEach {
            if let endTimeObserver = $0 {
                NotificationCenter.default.removeObserver(endTimeObserver)
            }
        }
    }
    
    // MARK: Overrides
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avPlayerLayer.frame = self.bounds
    }
    
    // MARK: Private methods
    private func setUpObservers() {
        endTimeObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { _ in
            print("Playback Stopped.")
        }
    }
    
    private func loadContent() {
        Task {
            await asset(
                withURL: url
            ) { [weak self] asset in
                guard let asset = asset else {
                    print("Asset could not be loaded.")
                    return
                }
                
                self?.loadAVPlayerItem(withAsset: asset)
            }
        }
    }
    
    private func asset(withURL url: URL, onLoading: @escaping (AVAsset?) -> Void) async {
        let asset = AVAsset(url: url)
        guard (try? await asset.load(.isPlayable)) == true else {
            onLoading(nil)
            return
        }
        
        switch asset.status(of: .isPlayable) {
        case .loaded:
            onLoading(asset)
            
        case .failed:
            onLoading(nil)
            
        default:
            break
        }
    }
    
    private func loadAVPlayerItem(withAsset asset: AVAsset) {
        playerItem = AVPlayerItem(asset: asset)
        playerItem?.addObserver(
            self,
            forKeyPath: Constants.statusKeyPath,
            options: [.old, .new],
            context: &playerItemContext
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.avPlayerLayer.player = AVPlayer(playerItem: self.playerItem)
            self.periodicTimeObserver = self.avPlayerLayer.player?.addPeriodicTimeObserver(
                forInterval: CMTimeMake(value: 1, timescale: 2), // notify every 0.5 seconds
                queue: .global()
            ) { time in
                let seconds = Int(time.seconds)
                // h:m:s
                print("Playhead position \(seconds / 3600):\((seconds % 3600) / 60):\(Double(seconds % 60) + (time.seconds - Double(seconds)))")
            }
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
        
        guard keyPath == Constants.statusKeyPath else {
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
