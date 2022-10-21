//
//  ViewController.swift
//  VideoPlayer
//
//  Created by Darshan Srinivasa on 10/20/22.
//

import UIKit

final class ViewController: UIViewController {
    enum Constants {
        static let videoURLString = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPlayer()
    }
    
    func setupPlayer() {
        guard let url = URL(string: Constants.videoURLString) else {
            return
        }
        
        let playerView = VideoPlayerView(url: url)
        view.addSubview(playerView)
        
        // setting up auto layout constraints for the `playerView`
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            playerView.heightAnchor.constraint(equalTo: view.heightAnchor),
            playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

