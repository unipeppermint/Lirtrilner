import UIKit

@MainActor final class LirtrilnerGameViewController: LirtrilnerPage {
  let level: LevelDefinition
  var session: GameSession
  let board = LirtrilnerBoardView()
  let orders = UIStackView()
  let moves = WorkshopStyle.label("", size: 23, weight: .bold)
  let supply = WorkshopStyle.label("", size: 14, color: WorkshopStyle.muted)
  let supplyParts = UIStackView()
  private var supplyWidth: NSLayoutConstraint!
  let message = WorkshopStyle.label("", size: 15, color: WorkshopStyle.blue)
  let saveStatus = WorkshopStyle.label("", size: 13, color: WorkshopStyle.coral)
  var hintTask: Task<Void, Never>?
  var solverTask: Task<HintResult, Never>?
  var hintGeneration = 0
  var settled = false
  private var compact: Bool { view.bounds.height < 750 }

  init(level: LevelDefinition, session: GameSession) {
    self.level = level
    self.session = session
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    let workbench = UIImageView(image: UIImage(named: "Lirtrilner-wood-v2"))
    workbench.frame = view.bounds
    workbench.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    workbench.contentMode = .scaleAspectFill
    workbench.alpha = 0.30
    view.insertSubview(workbench, at: 0)
    stack.spacing = 8
    message.font = WorkshopStyle.font(compact ? 12 : 14)
    supply.font = WorkshopStyle.font(compact ? 12 : 14)
    moves.font = WorkshopStyle.font(16, weight: .bold)
    moves.textAlignment = .center
    title =
      level.daily ? t("每日挑战", "Daily Challenge") : t("第 \(level.number) 关", "Level \(level.number)")
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "pause.circle"), style: .plain, target: self,
      action: #selector(pause))
    let subtitle =
      level.daily
      ? "\(session.dateKey ?? "") · " + t("题目 \(level.number)/30", "Puzzle \(level.number)/30")
      : context.toyName(level.toy) + " · "
        + t("维修阶段 \(level.stage)/3", "Repair stage \(level.stage)/3")
    if !compact { add(WorkshopStyle.label(subtitle, size: 17, weight: .bold)) }
    orders.axis = .horizontal
    orders.distribution = .fillEqually
    orders.spacing = 4
    let orderRow = UIStackView(arrangedSubviews: [orders, moves])
    orderRow.spacing = 8
    orderRow.alignment = .center
    moves.widthAnchor.constraint(equalToConstant: 62).isActive = true
    let orderCard = WorkshopStyle.card([orderRow], spacing: 0)
    orderCard.directionalLayoutMargins = NSDirectionalEdgeInsets(
      top: 9, leading: 10, bottom: 9, trailing: 10)
    add(orderCard)
    add(message)
    board.translatesAutoresizingMaskIntoConstraints = false
    board.heightAnchor.constraint(equalTo: board.widthAnchor).isActive = true
    board.onAction = { [weak self] action in self?.perform(action) }
    let boardWell = UIView()
    boardWell.addSubview(board)
    NSLayoutConstraint.activate([
      board.centerXAnchor.constraint(equalTo: boardWell.centerXAnchor),
      board.topAnchor.constraint(equalTo: boardWell.topAnchor),
      board.bottomAnchor.constraint(equalTo: boardWell.bottomAnchor),
      compact
        ? board.widthAnchor.constraint(equalToConstant: 280)
        : board.widthAnchor.constraint(equalTo: boardWell.widthAnchor),
    ])
    add(boardWell)
    supplyParts.spacing = 3
    supplyParts.alignment = .center
    supplyParts.setContentHuggingPriority(.required, for: .horizontal)
    supplyParts.setContentCompressionResistancePriority(.required, for: .horizontal)
    supplyWidth = supplyParts.widthAnchor.constraint(equalToConstant: 0)
    supplyWidth.isActive = true
    let supplyRow = UIStackView(arrangedSubviews: [supply, supplyParts])
    supplyRow.spacing = 8
    supplyRow.alignment = .center
    let supplyCard = WorkshopStyle.card([supplyRow], spacing: 0)
    supplyCard.directionalLayoutMargins = NSDirectionalEdgeInsets(
      top: 3, leading: 12, bottom: 3, trailing: 10)
    supplyCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    add(supplyCard)
    let deliver = LirtrilnerRepairAppearance.button(
      t("交付", "Deliver"), symbol: "shippingbox.fill", top: 0x80C7A1,
      bottom: 0x398B69, compact: compact) {
      [weak self] in self?.perform(.deliver)
    }
    let tools = UIStackView(arrangedSubviews: [
      deliver,
      LirtrilnerRepairAppearance.button(
        t("撤销", "Undo"), symbol: "arrow.uturn.backward", top: 0xFF8C72,
        bottom: 0xDA4936, compact: compact) { [weak self] in
        self?.undo()
      },
      LirtrilnerRepairAppearance.button(
        t("重开", "Restart"), symbol: "arrow.clockwise", top: 0x8DB7FF,
        bottom: 0x426DC7, compact: compact) { [weak self] in
        self?.restart()
      },
      LirtrilnerRepairAppearance.button(
        t("提示", "Hint"), symbol: "lightbulb.fill", top: 0xFFD978,
        bottom: 0xD99424, compact: compact) { [weak self] in self?.hint() },
    ])
    tools.spacing = 6
    tools.distribution = .fillEqually
    tools.translatesAutoresizingMaskIntoConstraints = false
    tools.backgroundColor = WorkshopStyle.cream.withAlphaComponent(0.96)
    tools.layer.cornerRadius = 20
    view.addSubview(tools)
    scrollBottom.isActive = false
    NSLayoutConstraint.activate([
      tools.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      tools.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      tools.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
      scroll.bottomAnchor.constraint(equalTo: tools.topAnchor, constant: -8),
    ])
    if let pan = board.gestureRecognizers?.first as? UIPanGestureRecognizer {
      scroll.panGestureRecognizer.require(toFail: pan)
    }
    add(
      WorkshopStyle.label(
        t(
          "金框交付 · 就位变绿 · 蓝框补给\n可从空格起手，仅滑动选中的行或列。",
          "Gold = delivery · Blue = supply\nStart on any cell; slide one row or column."
        ), size: compact ? 12 : 13, color: WorkshopStyle.muted))
    add(saveStatus)
    add(
      WorkshopStyle.button(t("规则手册", "Rule book"), symbol: "book") { [weak self] in
        self?.open(LirtrilnerRulesViewController())
      })
    NotificationCenter.default.addObserver(
      self, selector: #selector(saveChanged), name: .lirtrilnerSaveChanged, object: nil)
    update()
    commit()
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if session.state.status == .lost && presentedViewController == nil { showFailure() }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    invalidateHint()
  }
  private func commit() {
    context.save.record(session, level: level)
    context.persist()
  }
  @objc private func saveChanged() {
    saveStatus.text =
      context.saveError == nil
      ? "" : t("暂未保存。返回设置可重试；请暂勿关闭应用。", "Not saved. Retry in Settings; keep the app open.")
  }
  func update(animated: Bool = false) {
    moves.text = t(
      "步数\n\(session.state.remaining)", "Moves\n\(session.state.remaining)")
    orders.arrangedSubviews.forEach { $0.removeFromSuperview() }
    for order in session.state.orders {
      let mark = order.delivered == order.required ? "✓ " : ""
      let art = LirtrilnerRepairAppearance.part(order.kind, level: order.level, size: 38)
      let count = WorkshopStyle.label(
        mark + "\(order.delivered)/\(order.required)", size: 15, weight: .bold)
      let item = UIStackView(arrangedSubviews: [art, count])
      item.axis = .vertical
      item.alignment = .center
      item.spacing = 1
      item.isAccessibilityElement = true
      item.accessibilityLabel = context.partName(order.kind, order.level)
        + ", \(order.delivered)/\(order.required)"
      orders.addArrangedSubview(item)
    }
    board.render(session.state, level: level, animated: animated)
    supplyParts.arrangedSubviews.forEach { $0.removeFromSuperview() }
    supplyParts.isAccessibilityElement = false
    supplyParts.accessibilityLabel = nil
    supplyWidth.constant = 0
    if session.state.supplyIndex < level.supplies.count {
      let next = level.supplies[session.state.supplyIndex]
      let upcoming = Array(level.supplies.dropFirst(session.state.supplyIndex).prefix(2))
      supplyWidth.constant = CGFloat(upcoming.count * 36 + max(0, upcoming.count - 1) * 20)
      for (index, item) in upcoming.enumerated() {
        if index > 0 {
          supplyParts.addArrangedSubview(WorkshopStyle.label("→", size: 14))
        }
        supplyParts.addArrangedSubview(
          LirtrilnerRepairAppearance.part(item.kind, level: item.level, size: 36))
      }
      supplyParts.isAccessibilityElement = true
      supplyParts.accessibilityLabel = upcoming.map {
        context.partName($0.kind, $0.level)
      }.joined(separator: ", ")
      supply.text =
        (session.state.pendingSupply
          ? t("等待入口空出", "Entrance blocked") : t("接下来", "Next"))
        + (compact
          ? ""
          : "\n"
            + t(
              "入口：第 \(next.index/5+1) 行，第 \(next.index%5+1) 列",
              "Entrance: row \(next.index/5+1), column \(next.index%5+1)"))
    } else {
      supply.text = t(
        "补给已用完", "No more supplies")
    }
    if BoardEngine.matchingOrder(session.state) != nil {
      message.text = t("零件已就位！点击交付格或下方按钮。", "Ready! Tap the delivery cell or Deliver part.")
    } else if !level.daily && level.number <= 3 && session.history.isEmpty {
      message.text =
        [
          t("从底行任意格向右滑，将两个齿轮 I 合成 II。", "Swipe right on the bottom row to merge two Gear I parts."),
          t(
            "先向下滑第一列，再向右滑底行。只有精确等级能交付。",
            "Slide column 1 down, then the bottom row right. Match the order exactly."),
          t(
            "障碍会隔开轨道。向下滑第 4 列，再向右滑底行。",
            "Obstacles split tracks. Slide column 4 down, then the bottom row right."),
        ][level.number - 1]
    } else {
      message.text = t(
        "滑动一行或一列，合并并送达指定零件。", "Slide one row or column. Merge and deliver the exact parts.")
    }
  }
  func perform(_ action: GameAction) {
    guard !board.inputLocked else { return }
    invalidateHint()
    let transition = session.apply(action, level: level)
    guard transition.valid else {
      message.text =
        action.direction == nil
        ? t(
          "需要把订单指定的类型和等级送到金框交付格。",
          "Move a part of the exact requested type and level onto the gold delivery cell.")
        : t("这条轨道没有变化，不扣步。", "That track did not change. No move used.")
      UIAccessibility.post(notification: .announcement, argument: message.text)
      return
    }
    LirtrilnerAudioService.shared.play(
      action.direction == nil ? "deliver" : transition.merged ? "merge" : "move")
    commit()
    update()
    board.animate(transition)
    if session.state.status == .won {
      settle()
    } else if session.state.status == .lost {
      LirtrilnerAudioService.shared.play("fail")
      showFailure()
    }
  }

  private func showFailure() {
    let alert = UIAlertController(
      title: t("再试一次", "Try again"),
      message: session.state.remaining == 0
        ? t("步数用完了。撤销可以恢复上一状态。", "No moves left. Undo restores your previous position.")
        : t("没有可执行的滑动或交付。", "No slide or delivery is available."), preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: t("撤销", "Undo"), style: .default) { _ in self.undo() })
    alert.addAction(
      UIAlertAction(title: t("重开", "Restart"), style: .default) { _ in self.resetSession() })
    alert.addAction(
      UIAlertAction(title: t("返回工坊", "Workshop"), style: .cancel) { _ in
        self.navigationController?.popToRootViewController(animated: true)
      })
    present(alert, animated: true)
  }
  func undo() {
    invalidateHint()
    guard session.undo() else {
      message.text = t("没有可撤销的操作。", "Nothing to undo.")
      return
    }
    commit()
    update()
  }
  func restart() {
    confirm(
      t("重新开始？", "Restart this puzzle?"),
      t("本局步数和补给将重置，已收藏的玩具保留。", "This resets the puzzle and supplies. Your collection stays.")
    ) { self.resetSession() }
  }
  private func resetSession() {
    invalidateHint()
    let revision = session.state.revision + 1
    session = GameSession(state: BoardEngine.initial(level), dateKey: session.dateKey)
    session.state.revision = revision
    settled = false
    commit()
    update()
  }
  private func invalidateHint() {
    hintTask?.cancel()
    solverTask?.cancel()
    hintGeneration += 1
  }
  func hint() {
    invalidateHint()
    let token = hintGeneration
    let snapshot = session.state
    let definition = level
    message.text = t("正在寻找可验证的通关路线…", "Looking for a verified route…")
    let worker = Task.detached(priority: .userInitiated) {
      HintSolver.solve(state: snapshot, level: definition, cancelled: { Task.isCancelled })
    }
    solverTask = worker
    hintTask = Task { [weak self] in
      let result = await worker.value
      guard let self, !Task.isCancelled, self.hintGeneration == token,
        self.session.state.revision == snapshot.revision
      else { return }
      switch result {
      case .route(let route):
        guard let next = route.first else { return }
        if let direction = next.direction {
          self.message.text =
            self.t(
              "建议：第 \(next.index+1) \(direction.horizontal ? "行" : "列")，",
              "Hint: \(direction.horizontal ? "row" : "column") \(next.index+1), ")
            + self.board.directionName(direction)
        } else {
          self.message.text = self.t("建议：现在交付零件。", "Hint: deliver the part now.")
        }
      case .unknown, .cancelled:
        self.message.text = self.t(
          "暂未找到通关路线，可撤销或重开。", "No route found yet. You can undo or restart.")
      }
      UIAccessibility.post(notification: .announcement, argument: self.message.text)
    }
  }
  @objc func pause() {
    let alert = UIAlertController(
      title: t("维修暂停", "Repair paused"),
      message: t("当前进度已提交本地保存。", "Your current position is queued for saving."),
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: t("继续", "Resume"), style: .cancel))
    alert.addAction(
      UIAlertAction(title: t("重开", "Restart"), style: .default) { _ in self.restart() })
    alert.addAction(
      UIAlertAction(title: t("返回工坊", "Workshop"), style: .default) { _ in
        self.navigationController?.popToRootViewController(animated: true)
      })
    present(alert, animated: true)
  }
  private func settle() {
    guard !settled else { return }
    settled = true
    LirtrilnerAudioService.shared.play("complete")
    let result = LirtrilnerResultViewController(level: level, session: session)
    var controllers = navigationController?.viewControllers ?? []
    if !controllers.isEmpty { controllers.removeLast() }
    controllers.append(result)
    navigationController?.setViewControllers(controllers, animated: true)
  }
}
