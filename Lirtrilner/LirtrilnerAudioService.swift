import AVFoundation
import UIKit

@MainActor final class LirtrilnerAudioService {
  static let shared = LirtrilnerAudioService()
  private var music: AVAudioPlayer?
  private var effects: [String: AVAudioPlayer] = [:]
  private init() {
    try? AVAudioSession.sharedInstance().setCategory(
      .ambient, mode: .default, options: [.mixWithOthers])
    for name in ["music", "move", "merge", "deliver", "complete", "fail"] {
      guard let url = Bundle.main.url(forResource: "Lirtrilner-" + name, withExtension: "wav"),
        let player = try? AVAudioPlayer(contentsOf: url)
      else { continue }
      player.prepareToPlay()
      if name == "music" {
        player.numberOfLoops = -1
        player.volume = 0.18
        music = player
      } else {
        player.volume = 0.4
        effects[name] = player
      }
    }
    NotificationCenter.default.addObserver(
      self, selector: #selector(background), name: UIApplication.willResignActiveNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(configure), name: UIApplication.didBecomeActiveNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(interruption(_:)), name: AVAudioSession.interruptionNotification,
      object: nil)
  }
  @objc func configure() {
    if LirtrilnerContext.shared.save.settings.music
      && UIApplication.shared.applicationState == .active
    {
      music?.play()
    } else {
      music?.pause()
    }
  }
  @objc private func background() {
    music?.pause()
    effects.values.forEach { $0.stop() }
  }
  @objc private func interruption(_ note: Notification) {
    if (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
      == AVAudioSession.InterruptionType.ended.rawValue
    {
      configure()
    } else {
      background()
    }
  }
  func play(_ name: String) {
    let settings = LirtrilnerContext.shared.save.settings
    if settings.sound {
      effects[name]?.currentTime = 0
      effects[name]?.play()
    }
    if settings.haptics {
      UIImpactFeedbackGenerator(style: name == "complete" ? .medium : .light).impactOccurred()
    }
  }
}
