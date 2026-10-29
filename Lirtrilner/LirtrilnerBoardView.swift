import UIKit

@MainActor final class LirtrilnerBoardView: UIView {
  var onAction: ((GameAction) -> Void)?
  var cells: [UIButton] = []
  private var pieces: [LirtrilnerPartView] = []
  private var terrainArt: [UIImageView] = []
  private let supplyArt = LirtrilnerRepairAppearance.token(
    symbol: "arrow.down", top: 0x7BB5E9, bottom: 0x4776BA, size: 48)
  private var start: CGPoint?
  private var origin: Int?
  private var locked: Direction?
  private var state: GameState?
  private var level: LevelDefinition?
  private let context = LirtrilnerContext.shared
  private let wood = UIImageView(image: UIImage(named: "Lirtrilner-wood-v2"))
  private var highlighted: Set<Int> = []
  private var busy = false
  var inputLocked: Bool { busy }
  private var animationToken = 0
  private var overlays: [UIView] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = WorkshopStyle.wood
    wood.contentMode = .scaleAspectFill
    wood.clipsToBounds = true
    wood.layer.cornerRadius = 16
    addSubview(wood)
    layer.shadowColor = UIColor(hex: 0x6A3C1C).cgColor
    layer.shadowOpacity = 0.20
    layer.shadowOffset = CGSize(width: 0, height: 5)
    layer.shadowRadius = 7
    layer.cornerRadius = 18
    layer.borderWidth = 3
    layer.borderColor = UIColor(hex: 0xBC9365).cgColor
    for index in 0..<25 {
      let button = UIButton(type: .custom)
      button.tag = index
      button.layer.cornerRadius = 9
      button.layer.shadowColor = UIColor(hex: 0x714827).cgColor
      button.layer.shadowOpacity = 0.12
      button.layer.shadowRadius = 1
      button.layer.shadowOffset = CGSize(width: 0, height: 1)
      button.titleLabel?.numberOfLines = 0
      button.titleLabel?.textAlignment = .center
      button.addAction(UIAction { [weak self] _ in self?.tap(index) }, for: .touchUpInside)
      button.accessibilityCustomActions = Direction.allCases.map { direction in
        UIAccessibilityCustomAction(name: self.directionName(direction)) { [weak self] _ in
          self?.submit(.slide(direction, direction.horizontal ? index / 5 : index % 5))
          return true
        }
      }
      addSubview(button)
      cells.append(button)
      let terrain = UIImageView()
      terrain.contentMode = .scaleAspectFit
      terrain.isUserInteractionEnabled = false
      button.addSubview(terrain)
      terrainArt.append(terrain)
      let piece = LirtrilnerPartView()
      button.addSubview(piece)
      pieces.append(piece)
    }
    let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
    addGestureRecognizer(pan)
    NotificationCenter.default.addObserver(
      self, selector: #selector(interrupted), name: UIApplication.willResignActiveNotification,
      object: nil)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()
    wood.frame = bounds.insetBy(dx: 3, dy: 3)
    let gap: CGFloat = 5
    let size = (bounds.width - 20 - gap * 4) / 5
    for (i, cell) in cells.enumerated() {
      cell.frame = CGRect(
        x: 10 + CGFloat(i % 5) * (size + gap), y: 10 + CGFloat(i / 5) * (size + gap), width: size,
        height: size)
      pieces[i].frame = cell.bounds
      terrainArt[i].frame = cell.bounds
    }
  }

  func directionName(_ direction: Direction) -> String {
    switch direction {
    case .left: return context.text("此行向左滑动", "Slide row left")
    case .right: return context.text("此行向右滑动", "Slide row right")
    case .up: return context.text("此列向上滑动", "Slide column up")
    case .down: return context.text("此列向下滑动", "Slide column down")
    }
  }

  func render(_ state: GameState, level: LevelDefinition, animated: Bool = false) {
    if self.state?.revision != state.revision {
      animationToken += 1
      busy = false
      overlays.forEach { $0.removeFromSuperview() }
      overlays.removeAll()
      pieces.forEach {
        $0.isHidden = false
        $0.layer.removeAllAnimations()
        $0.transform = .identity
      }
    }
    self.state = state
    self.level = level
    let entry =
      state.supplyIndex < level.supplies.count ? level.supplies[state.supplyIndex].index : nil
    for (index, cell) in state.board.enumerated() {
      let button = cells[index]
      pieces[index].part = cell.part
      terrainArt[index].image = nil
      let canDeliver = cell.terrain == .delivery && BoardEngine.matchingOrder(state) != nil
      var title = ""
      if let part = cell.part {
        title = ""
        button.backgroundColor =
          part.kind == .gear
          ? UIColor(hex: 0xFAE4C3).withAlphaComponent(0.85)
          : UIColor(hex: 0xE1E8CA).withAlphaComponent(0.85)
        button.setTitleColor(WorkshopStyle.ink, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .bold)
      } else {
        if cell.terrain == .obstacle {
          terrainArt[index].image = UIImage(named: "Lirtrilner-obstacle-v4")
        } else if cell.terrain == .delivery {
          terrainArt[index].image = UIImage(named: "Lirtrilner-delivery-v4")
        } else if entry == index {
          terrainArt[index].image = supplyArt
        }
        button.backgroundColor =
          cell.terrain == .obstacle
          ? .clear : UIColor(hex: 0xF6E6CC).withAlphaComponent(0.65)
        button.setTitleColor(
          cell.terrain == .obstacle ? WorkshopStyle.cream : WorkshopStyle.muted, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
      }
      button.layer.borderWidth = cell.terrain == .obstacle ? 0
        : cell.terrain == .delivery || entry == index ? 3 : 1
      button.layer.borderColor =
        (canDeliver
        ? UIColor(hex: 0x28795C)
        : cell.terrain == .delivery
          ? UIColor(hex: 0xDDA32F) : entry == index ? WorkshopStyle.blue : UIColor(hex: 0xD5B58B))
        .cgColor
      button.setTitle(title, for: .normal)
      let coordinate = context.text(
        "第 \(index/5+1) 行，第 \(index%5+1) 列", "Row \(index/5+1), column \(index%5+1)")
      let content =
        cell.part.map { context.partName($0.kind, $0.level) }
        ?? context.text(
          cell.terrain == .obstacle ? "障碍" : "空格", cell.terrain == .obstacle ? "Obstacle" : "Empty")
      button.accessibilityLabel = coordinate + ", " + content
      button.accessibilityValue =
        (cell.terrain == .delivery ? context.text("交付格", "Delivery") : "")
        + (entry == index ? context.text("，补给入口", ", Supply entrance") : "")
      button.accessibilityHint =
        canDeliver
        ? context.text("轻点交付；也可通过操作菜单滑动", "Tap to deliver, or use actions to slide")
        : context.text("使用操作菜单选择行列方向", "Use actions to choose a direction")
      if highlighted.contains(index) {
        button.layer.borderColor = WorkshopStyle.blue.cgColor
        button.layer.borderWidth = 3
      }
    }
    if animated && !UIAccessibility.isReduceMotionEnabled {
      busy = true
      animationToken += 1
      let token = animationToken
      UIView.animate(withDuration: 0.10, animations: { self.alpha = 0.80 }) { _ in
        UIView.animate(withDuration: 0.10, animations: { self.alpha = 1 }) { _ in
          if self.animationToken == token { self.busy = false }
        }
      }
    }
  }

  func animate(_ transition: GameTransition) {
    guard !UIAccessibility.isReduceMotionEnabled else { return }
    layoutIfNeeded()
    busy = true
    animationToken += 1
    let token = animationToken
    for movement in transition.movements {
      let overlay = LirtrilnerPartView(frame: cells[movement.from].frame)
      overlay.part = movement.part
      addSubview(overlay)
      overlays.append(overlay)
      pieces[movement.to].isHidden = true
      UIView.animate(withDuration: 0.20, delay: 0, options: [.curveEaseInOut]) {
        overlay.frame = self.cells[movement.to].frame
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { [weak self] in
      guard let self, self.animationToken == token else { return }
      self.overlays.forEach { $0.removeFromSuperview() }
      self.overlays.removeAll()
      self.pieces.forEach { $0.isHidden = false }
      let merged = Set(transition.movements.filter(\.merged).map(\.to))
      for index in merged {
        self.pieces[index].transform = CGAffineTransform(scaleX: 1.13, y: 1.13)
      }
      UIView.animate(withDuration: 0.12) {
        self.pieces.forEach { $0.transform = .identity }
      } completion: { _ in
        if self.animationToken == token { self.busy = false }
      }
    }
  }

  private func tap(_ index: Int) {
    guard state?.board[index].terrain == .delivery else { return }
    submit(.deliver)
  }
  private func submit(_ action: GameAction) {
    guard !busy else { return }
    onAction?(action)
  }
  private func cell(at point: CGPoint) -> Int? {
    cells.firstIndex { $0.frame.contains(point) }
  }
  @objc private func pan(_ gesture: UIPanGestureRecognizer) {
    let point = gesture.location(in: self)
    switch gesture.state {
    case .began:
      guard !busy else { return }
      let translation = gesture.translation(in: self)
      let initial = CGPoint(x: point.x - translation.x, y: point.y - translation.y)
      start = initial
      origin = cell(at: initial)
      locked = nil
      lock(point)
    case .changed: lock(point)
    case .ended:
      if let direction = locked, let origin {
        submit(.slide(direction, direction.horizontal ? origin / 5 : origin % 5))
      }
      resetTrack()
    case .cancelled, .failed: resetTrack()
    default: break
    }
  }
  private func lock(_ point: CGPoint) {
    guard let start, let origin, locked == nil else { return }
    let dx = point.x - start.x
    let dy = point.y - start.y
    guard max(abs(dx), abs(dy)) >= 12 else { return }
    locked = abs(dx) > abs(dy) ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up)
    highlighted = Set(
      (0..<5).map { locked!.horizontal ? origin / 5 * 5 + $0 : $0 * 5 + origin % 5 })
    if let state, let level { render(state, level: level) }
  }
  private func resetTrack() {
    start = nil
    origin = nil
    locked = nil
    highlighted = []
    if let state, let level { render(state, level: level) }
  }
  @objc private func interrupted() {
    animationToken += 1
    layer.removeAllAnimations()
    alpha = 1
    busy = false
    overlays.forEach { $0.removeFromSuperview() }
    overlays = []
    pieces.forEach {
      $0.isHidden = false
      $0.transform = .identity
    }
    resetTrack()
  }
}
