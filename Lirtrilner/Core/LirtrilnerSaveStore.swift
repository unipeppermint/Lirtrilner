import Foundation

nonisolated struct WorkshopSettings: Codable, Equatable, Sendable {
  var music = true
  var sound = true
  var haptics = true
  var language = "system"
}

nonisolated struct SaveEnvelope: Codable, Equatable, Sendable {
  var schemaVersion = 1
  var revision = 0
  var story: GameSession?
  var daily: GameSession?
  var best: [String: Int] = [:]
  var dailyBest: [String: Int] = [:]
  var dailySelection: [String: String] = [:]
  var settings = WorkshopSettings()
  var tutorialSeen = false

  var completedCount: Int {
    (1...36).filter { best[String(format: "story-%02d", $0)] != nil }.count
  }
  var unlocked: Int {
    for number in 1...36 where best[String(format: "story-%02d", number)] == nil { return number }
    return 36
  }
  func stages(_ toy: Int) -> Int {
    (1...3).filter { best[String(format: "story-%02d", toy * 3 + $0)] != nil }.count
  }
  var collectionCount: Int { (0..<12).filter { stages($0) == 3 }.count }

  mutating func record(_ session: GameSession, level: LevelDefinition) {
    if level.daily { daily = session } else { story = session }
    if session.state.status == .won {
      let moves = level.moveLimit - session.state.remaining
      if level.daily, let date = session.dateKey {
        dailyBest[date] = min(dailyBest[date] ?? Int.max, moves)
      } else {
        best[level.id] = min(best[level.id] ?? Int.max, moves)
        tutorialSeen = true
      }
    }
    revision += 1
  }
}

// All disk operations run on this queue. A failed write never replaces the last
// valid snapshot. The caller receives an error and keeps its in-memory session.
nonisolated final class SaveStore: @unchecked Sendable {
  private let queue = DispatchQueue(label: "com.ztmpa.Lirtrilner.save")
  let directory: URL
  private var writtenRevision = -1
  private var preserveBackup = false
  private var quarantine = false
  var currentURL: URL { directory.appendingPathComponent("Lirtrilner-save.json") }
  var backupURL: URL { directory.appendingPathComponent("Lirtrilner-save.backup.json") }

  init(directory: URL) { self.directory = directory }

  func load() -> (SaveEnvelope, String?) {
    queue.sync {
      for (index, url) in [currentURL, backupURL].enumerated() {
        do {
          let data = try Data(contentsOf: url)
          let save = try JSONDecoder().decode(SaveEnvelope.self, from: data)
          guard save.schemaVersion == 1, save.revision >= 0, save.revision < Int.max - 1000,
            save.best.allSatisfy({ $0.value >= 0 && $0.value <= 60 })
          else { continue }
          writtenRevision = save.revision
          preserveBackup = index == 1
          return (save, index == 1 ? "backup" : nil)
        } catch { continue }
      }
      let hadFiles =
        FileManager.default.fileExists(atPath: currentURL.path)
        || FileManager.default.fileExists(atPath: backupURL.path)
      // Keep damaged files for explicit recovery; do not overwrite on launch.
      preserveBackup = hadFiles
      quarantine = hadFiles
      return (SaveEnvelope(), hadFiles ? "damaged" : nil)
    }
  }

  func write(_ save: SaveEnvelope, completion: @escaping @Sendable (String?) -> Void) {
    queue.async {
      do {
        try self.writeNow(save)
        completion(nil)
      } catch { completion(error.localizedDescription) }
    }
  }

  private func writeNow(_ save: SaveEnvelope) throws {
    guard save.revision >= writtenRevision else { return }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let data = try JSONEncoder().encode(save)
    if quarantine {
      for url in [currentURL, backupURL] {
        if let damaged = try? Data(contentsOf: url) {
          let recovery = directory.appendingPathComponent(url.lastPathComponent + ".damaged")
          if !FileManager.default.fileExists(atPath: recovery.path) {
            try damaged.write(to: recovery, options: .atomic)
          }
        }
      }
      quarantine = false
    }
    if !preserveBackup, let old = try? Data(contentsOf: currentURL),
      (try? JSONDecoder().decode(SaveEnvelope.self, from: old)) != nil
    {
      try old.write(to: backupURL, options: .atomic)
    }
    try data.write(to: currentURL, options: .atomic)
    preserveBackup = false
    writtenRevision = save.revision
  }

  func flush() { queue.sync {} }

  func reset(_ save: SaveEnvelope) throws {
    try queue.sync {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let data = try JSONEncoder().encode(save)
      // Keep the current file until the final atomic replacement succeeds.
      // If cleanup or replacement fails, the caller retains the old session.
      let backups = [
        backupURL,
        directory.appendingPathComponent(currentURL.lastPathComponent + ".damaged"),
        directory.appendingPathComponent(backupURL.lastPathComponent + ".damaged"),
      ]
      for url in backups where FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
      try data.write(to: currentURL, options: .atomic)
      writtenRevision = save.revision
      preserveBackup = false
      quarantine = false
    }
  }
}
