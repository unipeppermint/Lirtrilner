import Foundation

nonisolated enum HintResult: Sendable {
  case route([GameAction])
  case unknown
  case cancelled
}

nonisolated enum HintSolver {
  static func solve(
    state: GameState,
    level: LevelDefinition,
    nodeLimit: Int = 12_000,
    seconds: Double = 0.45,
    cancelled: () -> Bool = { false }
  ) -> HintResult {
    guard !cancelled() else { return .cancelled }
    // Reference routes are validated at load time. Only reuse a suffix when
    // the complete position matches and its remaining budget is sufficient.
    var referenceState = BoardEngine.initial(level)
    for offset in 0...level.reference.count {
      if !level.reference.isEmpty, BoardEngine.key(referenceState) == BoardEngine.key(state) {
        let suffix = Array(level.reference.dropFirst(offset))
        if suffix.filter({ $0.direction != nil }).count <= state.remaining {
          return .route(suffix)
        }
      }
      if offset < level.reference.count {
        referenceState =
          BoardEngine.apply(level.reference[offset], to: referenceState, level: level).after
      }
    }
    let deadline = Date.timeIntervalSinceReferenceDate + seconds
    var visited: [String: Int] = [:]
    var path: [GameAction] = []
    var nodes = 0
    var stopped = false
    func search(_ current: GameState) -> Bool {
      nodes += 1
      if nodes >= nodeLimit || Date.timeIntervalSinceReferenceDate >= deadline || cancelled() {
        stopped = true
        return false
      }
      if current.status == .won { return true }
      if current.status == .lost { return false }
      let key = BoardEngine.key(current)
      if let budget = visited[key], budget >= current.remaining { return false }
      visited[key] = current.remaining
      for action in BoardEngine.actions {
        let next = BoardEngine.apply(action, to: current, level: level)
        guard next.valid else { continue }
        path.append(action)
        if search(next.after) { return true }
        path.removeLast()
        if stopped { return false }
      }
      return false
    }
    if search(state) { return .route(path) }
    return cancelled() ? .cancelled : .unknown
  }
}
