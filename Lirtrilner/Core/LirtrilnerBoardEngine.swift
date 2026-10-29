import Foundation

nonisolated enum BoardEngine {
  static func initial(_ level: LevelDefinition) -> GameState {
    var state = GameState(
      levelID: level.id,
      contentVersion: level.contentVersion,
      board: level.board,
      orders: level.orders,
      remaining: level.moveLimit,
      nextID: (level.board.compactMap { $0.part?.id }.max() ?? 0) + 1
    )
    evaluate(&state)
    return state
  }

  static func deliveryIndex(_ state: GameState) -> Int? {
    state.board.firstIndex { $0.terrain == .delivery }
  }

  static func matchingOrder(_ state: GameState) -> Int? {
    guard let index = deliveryIndex(state), let part = state.board[index].part else { return nil }
    return state.orders.firstIndex {
      $0.kind == part.kind && $0.level == part.level && $0.delivered < $0.required
    }
  }

  static func apply(_ action: GameAction, to before: GameState, level: LevelDefinition)
    -> GameTransition
  {
    var after = before
    var merged = false
    var movements: [PartMovement] = []
    guard before.status != .won, before.status != .lost else {
      return GameTransition(before: before, after: before, valid: false)
    }
    if let direction = action.direction {
      guard before.remaining > 0, (0..<5).contains(action.index) else {
        return GameTransition(before: before, after: before, valid: false)
      }
      merged = move(&after, direction: direction, index: action.index, movements: &movements)
      guard after.board != before.board else {
        return GameTransition(before: before, after: before, valid: false)
      }
      after.remaining -= 1
      supply(&after, level: level)
    } else {
      guard let order = matchingOrder(after), let cell = deliveryIndex(after) else {
        return GameTransition(before: before, after: before, valid: false)
      }
      after.orders[order].delivered += 1
      after.board[cell].part = nil
      if after.pendingSupply { supply(&after, level: level) }
    }
    after.revision += 1
    evaluate(&after)
    return GameTransition(
      before: before, after: after, valid: true, merged: merged, movements: movements)
  }

  // Cells are processed from the leading edge. Outputs are never fed back into
  // the input list, so a newly merged part cannot merge twice in one command.
  @discardableResult
  static func move(_ state: inout GameState, direction: Direction, index: Int) -> Bool {
    var movements: [PartMovement] = []
    return move(&state, direction: direction, index: index, movements: &movements)
  }

  @discardableResult
  private static func move(
    _ state: inout GameState, direction: Direction, index: Int, movements: inout [PartMovement]
  ) -> Bool {
    var indices = (0..<5).map { direction.horizontal ? index * 5 + $0 : $0 * 5 + index }
    if direction.reversed { indices.reverse() }
    var segments: [[Int]] = [[]]
    for cell in indices {
      if state.board[cell].terrain == .obstacle {
        segments.append([])
      } else {
        segments[segments.count - 1].append(cell)
      }
    }
    var merged = false
    for segment in segments {
      let parts = segment.compactMap { state.board[$0].part }
      var result: [Part] = []
      var cursor = 0
      while cursor < parts.count {
        let part = parts[cursor]
        let destination = segment[result.count]
        let source = segment.first { state.board[$0].part?.id == part.id }!
        if cursor + 1 < parts.count,
          part.kind == parts[cursor + 1].kind,
          part.level == parts[cursor + 1].level,
          part.level < 4
        {
          movements.append(PartMovement(part: part, from: source, to: destination, merged: true))
          let other = parts[cursor + 1]
          let otherSource = segment.first { state.board[$0].part?.id == other.id }!
          movements.append(
            PartMovement(part: other, from: otherSource, to: destination, merged: true))
          result.append(Part(id: state.nextID, kind: part.kind, level: part.level + 1))
          state.nextID += 1
          cursor += 2
          merged = true
        } else {
          if source != destination {
            movements.append(PartMovement(part: part, from: source, to: destination, merged: false))
          }
          result.append(part)
          cursor += 1
        }
      }
      for (offset, cell) in segment.enumerated() {
        state.board[cell].part = offset < result.count ? result[offset] : nil
      }
    }
    return merged
  }

  private static func supply(_ state: inout GameState, level: LevelDefinition) {
    guard state.supplyIndex < level.supplies.count else {
      state.pendingSupply = false
      return
    }
    let item = level.supplies[state.supplyIndex]
    guard state.board[item.index].part == nil else {
      state.pendingSupply = true
      return
    }
    state.board[item.index].part = Part(id: state.nextID, kind: item.kind, level: item.level)
    state.nextID += 1
    state.supplyIndex += 1
    state.pendingSupply = false
  }

  static func evaluate(_ state: inout GameState) {
    if state.orders.allSatisfy({ $0.delivered == $0.required }) {
      state.status = .won
    } else if matchingOrder(state) != nil {
      state.status = .awaitingDelivery
    } else if state.remaining == 0 || !hasSlide(state) {
      state.status = .lost
    } else {
      state.status = .playing
    }
  }

  static func hasSlide(_ state: GameState) -> Bool {
    for direction in Direction.allCases {
      for index in 0..<5 {
        var copy = state
        move(&copy, direction: direction, index: index)
        if copy.board != state.board { return true }
      }
    }
    return false
  }

  static var actions: [GameAction] {
    [.deliver]
      + Direction.allCases.flatMap { direction in
        (0..<5).map { .slide(direction, $0) }
      }
  }

  // IDs and revisions do not affect reachability. Remaining moves are tracked
  // separately by the solver's dominance table.
  static func key(_ state: GameState) -> String {
    state.board.map { cell in
      if let part = cell.part { return "\(part.kind == .gear ? "g" : "b")\(part.level)" }
      return "_"
    }.joined() + ":" + state.orders.map { String($0.delivered) }.joined(separator: ",")
      + ":\(state.supplyIndex):\(state.pendingSupply)"
  }
}
