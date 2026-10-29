import Foundation

nonisolated struct ContentError: Error, CustomStringConvertible {
  var description: String
}

nonisolated enum LevelRepository {
  static func load(_ data: Data) throws -> [LevelDefinition] {
    // Reject unknown content keys, rather than silently accepting a newer schema.
    guard let roots = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      throw ContentError(description: "Invalid level document")
    }
    func keys(_ object: [String: Any], _ allowed: Set<String>) throws {
      guard Set(object.keys).isSubset(of: allowed) else {
        throw ContentError(description: "Unsupported content field")
      }
    }
    for root in roots {
      try keys(
        root,
        [
          "schemaVersion", "contentVersion", "id", "number", "daily", "toy", "stage", "board",
          "orders", "moveLimit", "supplies", "reference",
        ])
      for cell in root["board"] as? [[String: Any]] ?? [] {
        try keys(cell, ["terrain", "part"])
        if let part = cell["part"] as? [String: Any] { try keys(part, ["id", "kind", "level"]) }
      }
      for order in root["orders"] as? [[String: Any]] ?? [] {
        try keys(order, ["kind", "level", "required", "delivered"])
      }
      for item in root["supplies"] as? [[String: Any]] ?? [] {
        try keys(item, ["index", "kind", "level"])
      }
      for action in root["reference"] as? [[String: Any]] ?? [] {
        try keys(action, ["direction", "index"])
      }
    }
    let levels = try JSONDecoder().decode([LevelDefinition].self, from: data)
    guard levels.count == 66,
      levels.filter({ !$0.daily }).map(\.number).sorted() == Array(1...36),
      levels.filter(\.daily).map(\.number).sorted() == Array(1...30),
      Set(levels.map(\.id)).count == 66
    else {
      throw ContentError(description: "Expected 36 story and 30 daily levels")
    }
    for level in levels { try validate(level) }
    return levels
  }

  static func validate(_ level: LevelDefinition) throws {
    let parts = level.board.compactMap(\.part)
    guard level.schemaVersion == 1, level.contentVersion == 1,
      level.board.count == 25,
      level.board.filter({ $0.terrain == .delivery }).count == 1,
      level.board.allSatisfy({ $0.terrain != .obstacle || $0.part == nil }),
      parts.allSatisfy({ (1...4).contains($0.level) && $0.id > 0 }),
      Set(parts.map(\.id)).count == parts.count,
      !level.orders.isEmpty,
      level.orders.allSatisfy({
        (1...4).contains($0.level) && (1...4).contains($0.required) && $0.delivered == 0
      }),
      (1...60).contains(level.moveLimit),
      (0..<12).contains(level.toy), (1...3).contains(level.stage),
      level.daily
        || (level.toy == (level.number - 1) / 3 && level.stage == (level.number - 1) % 3 + 1),
      level.supplies.allSatisfy({
        (0..<25).contains($0.index) && (1...4).contains($0.level)
          && level.board[$0.index].terrain != .obstacle
      })
    else {
      throw ContentError(description: "Invalid structure: \(level.id)")
    }
    var state = BoardEngine.initial(level)
    for (index, action) in level.reference.enumerated() {
      let transition = BoardEngine.apply(action, to: state, level: level)
      guard transition.valid else {
        throw ContentError(description: "Invalid reference action \(index): \(level.id)")
      }
      state = transition.after
      try validate(state, level: level)
    }
    guard state.status == .won else {
      throw ContentError(description: "Unsolved reference: \(level.id)")
    }
  }

  static func validate(_ state: GameState, level: LevelDefinition) throws {
    guard state.board.count == 25, state.orders.count == level.orders.count else {
      throw ContentError(description: "Invalid saved board size")
    }
    let parts = state.board.compactMap(\.part)
    guard state.levelID == level.id, state.contentVersion == level.contentVersion,
      (0...level.moveLimit).contains(state.remaining),
      (0...level.supplies.count).contains(state.supplyIndex),
      state.revision >= 0, state.revision < Int.max - 1000,
      (1...10000).contains(state.nextID),
      state.board.enumerated().allSatisfy({ index, cell in
        cell.terrain == level.board[index].terrain
          && (cell.terrain != .obstacle || cell.part == nil)
      }),
      parts.allSatisfy({ (1...4).contains($0.level) && $0.id > 0 && $0.id < state.nextID }),
      Set(parts.map(\.id)).count == parts.count,
      state.orders.enumerated().allSatisfy({ index, order in
        order.kind == level.orders[index].kind && order.level == level.orders[index].level
          && order.required == level.orders[index].required
          && (0...order.required).contains(order.delivered)
      }),
      !state.pendingSupply || state.supplyIndex < level.supplies.count
    else {
      throw ContentError(description: "Invalid saved state: \(level.id)")
    }
    var recomputed = state
    BoardEngine.evaluate(&recomputed)
    guard recomputed.status == state.status else {
      throw ContentError(description: "Inconsistent saved status")
    }
  }
}

nonisolated enum DailySchedule {
  static func key(_ date: Date, timeZone: TimeZone = .current) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
  }

  static func number(_ key: String) -> Int {
    let values = key.split(separator: "-").compactMap { Int($0) }
    guard values.count == 3 else { return 1 }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let anchor = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    guard
      let day = calendar.date(
        from: DateComponents(year: values[0], month: values[1], day: values[2]))
    else { return 1 }
    let difference = calendar.dateComponents([.day], from: anchor, to: day).day!
    return ((difference % 30) + 30) % 30 + 1
  }
}
