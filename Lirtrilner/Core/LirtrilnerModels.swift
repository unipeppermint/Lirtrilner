import Foundation

nonisolated enum PartKind: String, Codable, Sendable, CaseIterable {
  case gear, battery
}

nonisolated struct Part: Codable, Equatable, Sendable {
  var id: Int
  var kind: PartKind
  var level: Int
}

nonisolated enum Terrain: String, Codable, Sendable {
  case normal, obstacle, delivery
}

nonisolated struct BoardCell: Codable, Equatable, Sendable {
  var terrain: Terrain = .normal
  var part: Part?
}

nonisolated struct Order: Codable, Equatable, Sendable {
  var kind: PartKind
  var level: Int
  var required: Int
  var delivered: Int = 0
}

nonisolated struct Supply: Codable, Equatable, Sendable {
  var index: Int
  var kind: PartKind
  var level: Int
}

nonisolated enum Direction: String, Codable, Sendable, CaseIterable {
  case left, right, up, down
  var horizontal: Bool { self == .left || self == .right }
  var reversed: Bool { self == .right || self == .down }
}

nonisolated struct GameAction: Codable, Equatable, Sendable {
  var direction: Direction?
  var index: Int
  static let deliver = GameAction(direction: nil, index: 0)
  static func slide(_ direction: Direction, _ index: Int) -> GameAction {
    GameAction(direction: direction, index: index)
  }
}

nonisolated enum GameStatus: String, Codable, Sendable {
  case playing, awaitingDelivery, won, lost
}

nonisolated struct LevelDefinition: Codable, Sendable {
  var schemaVersion: Int
  var contentVersion: Int
  var id: String
  var number: Int
  var daily: Bool
  var toy: Int
  var stage: Int
  var board: [BoardCell]
  var orders: [Order]
  var moveLimit: Int
  var supplies: [Supply]
  var reference: [GameAction]
}

nonisolated struct GameState: Codable, Equatable, Sendable {
  var levelID: String
  var contentVersion: Int
  var board: [BoardCell]
  var orders: [Order]
  var remaining: Int
  var supplyIndex: Int = 0
  var pendingSupply: Bool = false
  var nextID: Int
  var revision: Int = 0
  var status: GameStatus = .playing
}

nonisolated struct PartMovement: Equatable, Sendable {
  var part: Part
  var from: Int
  var to: Int
  var merged: Bool
}

nonisolated struct GameTransition: Sendable {
  var before: GameState
  var after: GameState
  var valid: Bool
  var merged: Bool = false
  var movements: [PartMovement] = []
}

nonisolated struct GameSession: Codable, Equatable, Sendable {
  var state: GameState
  var history: [GameState] = []
  var dateKey: String?

  mutating func apply(_ action: GameAction, level: LevelDefinition) -> GameTransition {
    let transition = BoardEngine.apply(action, to: state, level: level)
    if transition.valid {
      history.append(state)
      if history.count > 100 { history.removeFirst() }
      state = transition.after
    }
    return transition
  }

  @discardableResult
  mutating func undo() -> Bool {
    guard state.status != .won, var previous = history.popLast() else { return false }
    previous.revision = state.revision + 1
    state = previous
    return true
  }
}
