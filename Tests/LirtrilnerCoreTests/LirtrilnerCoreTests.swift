import XCTest

@testable import LirtrilnerCore

final class LirtrilnerCoreTests: XCTestCase {
  func levels() throws -> [LevelDefinition] {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
    return try LevelRepository.load(
      Data(contentsOf: root.appendingPathComponent("Lirtrilner/Lirtrilner-levels.json")))
  }

  func fixture(
    parts: [(Int, PartKind, Int)], obstacles: [Int] = [], delivery: Int = 24, moves: Int = 20,
    supplies: [Supply] = []
  ) -> LevelDefinition {
    var board = Array(repeating: BoardCell(), count: 25)
    board[delivery].terrain = .delivery
    for i in obstacles { board[i].terrain = .obstacle }
    for (id, item) in parts.enumerated() {
      board[item.0].part = Part(id: id + 1, kind: item.1, level: item.2)
    }
    return LevelDefinition(
      schemaVersion: 1, contentVersion: 1, id: "test", number: 1, daily: false, toy: 0, stage: 1,
      board: board, orders: [Order(kind: .gear, level: 2, required: 1)], moveLimit: moves,
      supplies: supplies, reference: [])
  }

  func testAll66ReferencesAndUndo() throws {
    let content = try levels()
    XCTAssertEqual(content.count, 66)
    for level in content {
      var session = GameSession(state: BoardEngine.initial(level))
      for action in level.reference {
        let before = session.state
        let transition = session.apply(action, level: level)
        XCTAssertTrue(transition.valid, level.id)
        try LevelRepository.validate(session.state, level: level)
        if session.state.status != .won {
          XCTAssertTrue(session.undo())
          var restored = session.state
          restored.revision = before.revision
          XCTAssertEqual(restored, before)
          XCTAssertTrue(session.apply(action, level: level).valid)
        }
      }
      XCTAssertEqual(session.state.status, .won, level.id)
      XCTAssertFalse(session.undo())
    }
  }

  func testMergeDirectionBarrierAndCap() {
    for direction in Direction.allCases {
      let horizontal = direction.horizontal
      let positions = (0..<4).map { horizontal ? $0 : $0 * 5 }
      let level = fixture(parts: positions.map { ($0, .gear, 1) })
      var state = BoardEngine.initial(level)
      BoardEngine.move(&state, direction: direction, index: 0)
      XCTAssertEqual(state.board.compactMap(\.part).map(\.level), [2, 2])
    }
    let level = fixture(
      parts: [(0, .gear, 4), (1, .gear, 4), (3, .battery, 1), (4, .gear, 1)], obstacles: [2])
    let original = BoardEngine.initial(level)
    var state = original
    BoardEngine.move(&state, direction: .left, index: 0)
    XCTAssertEqual(state.board, original.board)
  }

  func testPendingSupplyDeliveryAndLastMove() {
    var level = fixture(
      parts: [(24, .gear, 2), (0, .battery, 1)], moves: 1,
      supplies: [
        Supply(index: 24, kind: .battery, level: 2), Supply(index: 1, kind: .gear, level: 1),
      ])
    level.orders.append(Order(kind: .battery, level: 2, required: 1))
    var session = GameSession(state: BoardEngine.initial(level))
    XCTAssertTrue(session.apply(.slide(.right, 0), level: level).valid)
    XCTAssertEqual(session.state.remaining, 0)
    XCTAssertTrue(session.state.pendingSupply)
    XCTAssertEqual(session.state.supplyIndex, 0)
    XCTAssertEqual(session.state.status, .awaitingDelivery)
    XCTAssertTrue(session.apply(.deliver, level: level).valid)
    XCTAssertEqual(session.state.supplyIndex, 1)
    XCTAssertEqual(session.state.board[24].part?.kind, .battery)
    XCTAssertTrue(session.undo())
    XCTAssertTrue(session.state.pendingSupply)
    XCTAssertEqual(session.state.orders[0].delivered, 0)
    _ = session.apply(.deliver, level: level)
    XCTAssertTrue(session.apply(.deliver, level: level).valid)
    XCTAssertEqual(session.state.status, .won)
    XCTAssertEqual(session.state.supplyIndex, 1)
  }

  func testInvalidSlideExactOrderAndLoss() {
    let level = fixture(parts: [(24, .battery, 2)], moves: 1)
    var session = GameSession(state: BoardEngine.initial(level))
    XCTAssertFalse(session.apply(.deliver, level: level).valid)
    XCTAssertFalse(session.apply(.slide(.right, 4), level: level).valid)
    XCTAssertEqual(session.history.count, 0)
    XCTAssertEqual(session.state.remaining, 1)
    XCTAssertTrue(session.apply(.slide(.left, 4), level: level).valid)
    XCTAssertEqual(session.state.status, .lost)
    XCTAssertTrue(session.undo())
    XCTAssertEqual(session.state.status, .playing)
  }

  func testHintsReplayAndBudgetCancellation() throws {
    for level in try levels() {
      let state = BoardEngine.initial(level)
      guard case .route(let actions) = HintSolver.solve(state: state, level: level) else {
        return XCTFail(level.id)
      }
      var current = state
      for action in actions { current = BoardEngine.apply(action, to: current, level: level).after }
      XCTAssertEqual(current.status, .won)
    }
    let level = fixture(parts: [(0, .gear, 1), (1, .gear, 1)])
    let state = BoardEngine.initial(level)
    if case .unknown = HintSolver.solve(state: state, level: level, nodeLimit: 0) {
    } else {
      XCTFail()
    }
    if case .cancelled = HintSolver.solve(state: state, level: level, cancelled: { true }) {
    } else {
      XCTFail()
    }
  }

  func testCalendarAndIdempotentRewards() throws {
    XCTAssertEqual(DailySchedule.number("2026-01-01"), 1)
    XCTAssertEqual(DailySchedule.number("2026-01-31"), 1)
    XCTAssertEqual(DailySchedule.number("2025-12-31"), 30)
    XCTAssertEqual(
      (DailySchedule.number("2028-03-01") - DailySchedule.number("2028-02-28") + 30) % 30, 2)
    var save = SaveEnvelope()
    let content = try levels()
    for level in content.prefix(3) {
      var session = GameSession(state: BoardEngine.initial(level))
      for action in level.reference { _ = session.apply(action, level: level) }
      save.record(session, level: level)
      save.record(session, level: level)
    }
    XCTAssertEqual(save.completedCount, 3)
    XCTAssertEqual(save.collectionCount, 1)
    XCTAssertEqual(save.stages(1), 0)
  }

  func testSaveBackupOrderingAndReset() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let store = SaveStore(directory: dir)
    var save = SaveEnvelope()
    save.revision = 1
    store.write(save) { XCTAssertNil($0) }
    store.flush()
    save.revision = 2
    save.best["story-01"] = 1
    store.write(save) { XCTAssertNil($0) }
    store.flush()
    var stale = SaveEnvelope()
    stale.revision = 0
    store.write(stale) { XCTAssertNil($0) }
    store.flush()
    XCTAssertEqual(store.load().0, save)
    try Data("broken".utf8).write(to: store.currentURL)
    XCTAssertEqual(store.load().1, "backup")
    XCTAssertEqual(store.load().0.revision, 1)
    try store.reset(SaveEnvelope())
    XCTAssertEqual(store.load().0, SaveEnvelope())
    XCTAssertFalse(FileManager.default.fileExists(atPath: store.backupURL.path))
  }

  func testSupplyExhaustionAndInvalidInputDoNotAdvance() {
    let level = fixture(
      parts: [(0, .gear, 1), (2, .gear, 1)], supplies: [Supply(index: 4, kind: .battery, level: 1)])
    var session = GameSession(state: BoardEngine.initial(level))
    XCTAssertFalse(session.apply(.slide(.left, 8), level: level).valid)
    XCTAssertEqual(session.state.supplyIndex, 0)
    XCTAssertTrue(session.apply(.slide(.left, 0), level: level).valid)
    XCTAssertEqual(session.state.supplyIndex, 1)
    XCTAssertFalse(session.state.pendingSupply)
    XCTAssertTrue(session.apply(.slide(.down, 4), level: level).valid)
    XCTAssertEqual(session.state.supplyIndex, 1)
    XCTAssertEqual(session.state.board.compactMap(\.part).count, 2)
  }

  func testDuplicateObjectivesAndNoDoubleDelivery() {
    var level = fixture(parts: [(24, .gear, 2), (0, .battery, 1)])
    level.orders.append(Order(kind: .gear, level: 2, required: 1))
    var session = GameSession(state: BoardEngine.initial(level))
    XCTAssertTrue(session.apply(.deliver, level: level).valid)
    XCTAssertEqual(session.state.orders.map(\.delivered), [1, 0])
    XCTAssertFalse(session.apply(.deliver, level: level).valid)
    XCTAssertEqual(session.history.count, 1)
  }

  func testIndependentModesAndCodableHistory() throws {
    let content = try levels()
    var save = SaveEnvelope()
    let story = content[0]
    let daily = content[36]
    var a = GameSession(state: BoardEngine.initial(story))
    var b = GameSession(state: BoardEngine.initial(daily), dateKey: "2026-10-28")
    _ = a.apply(story.reference[0], level: story)
    _ = b.apply(daily.reference[0], level: daily)
    save.record(a, level: story)
    save.record(b, level: daily)
    let decoded = try JSONDecoder().decode(SaveEnvelope.self, from: JSONEncoder().encode(save))
    XCTAssertEqual(decoded.story, a)
    XCTAssertEqual(decoded.daily, b)
    XCTAssertEqual(decoded, save)
    for action in daily.reference.dropFirst() { _ = b.apply(action, level: daily) }
    save.record(b, level: daily)
    XCTAssertEqual(save.completedCount, 0)
    XCTAssertEqual(save.collectionCount, 0)
    XCTAssertNotNil(save.dailyBest["2026-10-28"])
  }

  func testSaveWriteFailureAndDamagedQuarantine() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    try Data("not a directory".utf8).write(to: dir)
    let failing = SaveStore(directory: dir)
    let failed = expectation(description: "write error")
    failing.write(SaveEnvelope()) { error in
      XCTAssertNotNil(error)
      failed.fulfill()
    }
    wait(for: [failed], timeout: 2)
    try FileManager.default.removeItem(at: dir)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let store = SaveStore(directory: dir)
    try Data("damaged".utf8).write(to: store.currentURL)
    XCTAssertEqual(store.load().1, "damaged")
    store.write(SaveEnvelope()) { _ in }
    store.flush()
    XCTAssertEqual(
      try String(
        contentsOf: dir.appendingPathComponent("Lirtrilner-save.json.damaged"), encoding: .utf8),
      "damaged")
    XCTAssertNil(store.load().1)
  }

  func testRejectUnsupportedContentAndMalformedState() throws {
    let level = try levels()[0]
    var state = BoardEngine.initial(level)
    state.board[0].terrain = .obstacle
    XCTAssertThrowsError(try LevelRepository.validate(state, level: level))
    state = BoardEngine.initial(level)
    state.nextID = Int.max
    XCTAssertThrowsError(try LevelRepository.validate(state, level: level))
    var bad = level
    bad.schemaVersion = 99
    XCTAssertThrowsError(try LevelRepository.validate(bad))
    let data = try JSONSerialization.data(withJSONObject: [["unsupported": true]])
    XCTAssertThrowsError(try LevelRepository.load(data))
  }

  func testDeterministicReplayAndMovementEvents() throws {
    for level in try levels() {
      var first = BoardEngine.initial(level)
      var second = first
      for action in level.reference {
        let a = BoardEngine.apply(action, to: first, level: level)
        let b = BoardEngine.apply(action, to: second, level: level)
        XCTAssertEqual(a.after, b.after)
        XCTAssertEqual(a.movements, b.movements)
        for motion in a.movements {
          XCTAssertEqual(first.board[motion.from].part, motion.part)
          XCTAssertNotEqual(a.after.board[motion.to].terrain, .obstacle)
        }
        first = a.after
        second = b.after
      }
      print(
        "VERIFIED \(level.id): \(level.reference.filter {$0.direction != nil}.count)/\(level.moveLimit) slides, \(level.orders.reduce(0) {$0+$1.required}) deliveries, \(level.supplies.count) supplies"
      )
    }
  }

  func testBoundedSearchOffReferenceAndUndoLimit() {
    let level = fixture(parts: [(0, .gear, 1), (1, .gear, 1)], moves: 5)
    let state = BoardEngine.initial(level)
    guard case .route(let route) = HintSolver.solve(state: state, level: level, seconds: 1) else {
      return XCTFail("Expected a complete search route")
    }
    var end = state
    for action in route { end = BoardEngine.apply(action, to: end, level: level).after }
    XCTAssertEqual(end.status, .won)
    var session = GameSession(state: state, history: Array(repeating: state, count: 100))
    XCTAssertTrue(session.apply(.slide(.right, 0), level: level).valid)
    XCTAssertEqual(session.history.count, 100)
  }
}
