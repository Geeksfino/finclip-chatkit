import UIKit
import AVFoundation
import AVKit

/// Displays a video splash screen at app startup
class SplashViewController: UIViewController {
  
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var completion: (() -> Void)?
  private var timeObserver: Any?
  private var timeoutWorkItem: DispatchWorkItem?
  
  // MARK: - Initialization
  
  init(completion: @escaping () -> Void) {
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    setupVideoPlayer()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    playVideo()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    playerLayer?.frame = view.bounds
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
    player?.pause()
    if let obs = timeObserver, let player = player {
      player.removeTimeObserver(obs)
    }
    timeoutWorkItem?.cancel()
  }
  
  // MARK: - Video Setup
  
  private func setupVideoPlayer() {
    // Try to load video from bundle (case-insensitive, multiple extensions)
    guard let videoURL = findSplashVideoURL() else {
      print("⚠️ Splash video not found (tried splash.mp4/MP4/mov/MOV). Skipping splash screen.")
      transitionToMainApp()
      return
    }
    print("✅ Splash video found at: \(videoURL.path)")
    
    // Create player
    let player = AVPlayer(url: videoURL)
    self.player = player
    player.actionAtItemEnd = .pause
    
    // Create player layer
    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.frame = view.bounds
    playerLayer.videoGravity = .resizeAspectFill
    view.layer.addSublayer(playerLayer)
    self.playerLayer = playerLayer
    
    // Observe when video finishes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(videoDidFinish),
      name: .AVPlayerItemDidPlayToEndTime,
      object: player.currentItem
    )
    
    // Observe playback progress (for debugging)
    let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      guard let self else { return }
      let seconds = CMTimeGetSeconds(time)
      if seconds > 0 {
        // Playback has started
        // print("▶️ Splash playback seconds: \(seconds)") // uncomment to spam logs
      }
    }
    
    // Add tap gesture to skip
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(skipSplash))
    view.addGestureRecognizer(tapGesture)
  }
  
  private func playVideo() {
    // Safety timeout in case playback fails silently
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      print("⏱️ Splash timeout reached, transitioning to main app.")
      self.transitionToMainApp()
    }
    timeoutWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: work)

    player?.play()
  }
  
  // MARK: - Actions
  
  @objc private func videoDidFinish() {
    timeoutWorkItem?.cancel()
    transitionToMainApp()
  }
  
  @objc private func skipSplash() {
    player?.pause()
    timeoutWorkItem?.cancel()
    transitionToMainApp()
  }
  
  private func transitionToMainApp() {
    // Ensure we only transition once
    guard let completion = completion else { return }
    self.completion = nil
    
    // Animate transition
    UIView.animate(withDuration: 0.3, animations: {
      self.view.alpha = 0
    }) { _ in
      completion()
    }
  }

  // MARK: - Helpers
  
  private func findSplashVideoURL() -> URL? {
    // Common extensions to try (both cases)
    let exts = ["mp4", "MP4", "mov", "MOV"]
    // 1) Try in known subdirectory where we copy resources: "Videos"
    for ext in exts {
      if let url = Bundle.main.url(forResource: "splash", withExtension: ext, subdirectory: "Videos") {
        return url
      }
    }
    // 2) Try at bundle root (in case resources were flattened)
    for ext in exts {
      if let url = Bundle.main.url(forResource: "splash", withExtension: ext) {
        return url
      }
    }
    // Fallback: scan all bundle resource URLs for filenames matching case-insensitively
    // This helps in case the bundling preserved folder structure or unexpected casing
    if let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Videos") ??
                  Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) {
      if let match = urls.first(where: { $0.lastPathComponent.lowercased() == "splash.mp4" || $0.lastPathComponent.lowercased() == "splash.mov" }) {
        return match
      }
    }
    return nil
  }
}
