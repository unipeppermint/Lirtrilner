import UIKit

@MainActor final class LirtrilnerWorkshopViewController: LirtrilnerPage {
  var firstAppearance = true
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.backButtonTitle = ""
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    render()
    LirtrilnerAudioService.shared.configure()
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard firstAppearance else { return }
    firstAppearance = false
    if let error = context.contentError {
      notice(
        t("内容无法加载", "Content unavailable"),
        t("请重新安装正版应用。错误：", "Please reinstall the app. Error: ") + error)
      return
    }
    if let recovery = context.recovery {
      context.recovery = nil
      let details =
        recovery == "backup"
        ? t(
          "主存档异常，已恢复上一份有效备份。",
          "The latest save was damaged. The previous valid backup was restored.")
        : recovery == "session"
          ? t(
            "进行中的关卡与当前内容不兼容，已保留永久成绩并重开受影响关卡。",
            "An active puzzle was incompatible. Permanent results were kept; the affected puzzle will restart."
          )
          : t(
            "主存档和备份均无法读取。原文件保留在应用数据中。继续游玩会建立新进度；请先通过系统备份保留数据。",
            "Both saves could not be read. Original files remain in app storage. Playing will create new progress; preserve device backups before continuing."
          )
      notice(t("存档恢复", "Save recovery"), details)
    } else if !context.save.tutorialSeen && context.save.story == nil {
      openGame(context.level(1))
    }
  }
  private func render() {
    clear()
    title = t("工坊", "Workshop")
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "gearshape"), style: .plain, target: self,
      action: #selector(settings))
    heading(
      t("发条修理铺", "Clockwork Workshop"),
      subtitle: t("一枚发条，一段重新开始的故事", "Small parts. Wonderful second beginnings."))
    guard context.contentError == nil else { return }
    let number = context.save.unlocked
    let toy = (number - 1) / 3
    let art = LirtrilnerToyView()
    art.toy = toy
    art.stage = context.save.stages(toy)
    art.accessibilityLabel = context.toyName(toy)
    art.heightAnchor.constraint(equalToConstant: 260).isActive = true
    add(art)
    let complete = context.save.completedCount == 36
    add(
      WorkshopStyle.card([
        WorkshopStyle.label(
          complete ? t("收藏完成", "Collection complete") : t("今日委托", "ON THE WORKBENCH"), size: 13,
          weight: .bold, color: WorkshopStyle.coral),
        WorkshopStyle.label(
          complete ? t("十二件玩具，又动起来了", "Twelve toys, brought back to life") : context.toyName(toy),
          size: 24, weight: .bold),
        WorkshopStyle.label(
          t(
            "主线进度 \(context.save.completedCount)/36 · 修复收藏 \(context.save.collectionCount)/12",
            "Story \(context.save.completedCount)/36 · Collection \(context.save.collectionCount)/12"
          ), size: 15, color: WorkshopStyle.muted),
      ]))
    if !complete {
      add(
        WorkshopStyle.button(t("继续维修", "Continue repair"), symbol: "arrow.right", primary: true) {
          [weak self] in
          guard let self else { return }
          if let saved = self.context.save.story, saved.state.status != .won,
            let level = self.context.levels.first(where: { $0.id == saved.state.levelID })
          {
            self.openGame(level)
          } else {
            self.openGame(self.context.level(self.context.save.unlocked))
          }
        })
    }
    add(
      WorkshopStyle.button(
        t("主线关卡 · 36 道委托", "Story puzzles · 36 repairs"), symbol: "square.grid.3x3"
      ) { [weak self] in self?.open(LirtrilnerLevelsViewController()) })
    add(
      WorkshopStyle.button(
        t(
          "修复收藏 · \(context.save.collectionCount)/12",
          "Toy collection · \(context.save.collectionCount)/12"), symbol: "sparkles"
      ) { [weak self] in self?.open(LirtrilnerCollectionViewController()) })
    add(
      WorkshopStyle.button(t("每日挑战", "Daily Challenge"), symbol: "calendar") { [weak self] in
        guard let self else { return }
        if self.context.save.best["story-03"] == nil {
          self.notice(
            self.t("完成第 3 关后开放", "Unlock after level 3"),
            self.t("先修好第一件玩具，再来挑战每日委托。", "Restore your first toy to unlock daily repairs."))
        } else {
          self.open(LirtrilnerDailyViewController())
        }
      })
    add(
      WorkshopStyle.label(
        t("全部玩法免费 · 无广告 · 离线游玩", "All puzzles free · No ads · Play offline"), size: 13,
        color: WorkshopStyle.muted))
  }
  @objc private func settings() { open(LirtrilnerSettingsViewController()) }
}

@MainActor final class LirtrilnerLevelsViewController: LirtrilnerPage {
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    clear()
    title = t("主线关卡", "Story puzzles")
    let chapters = [
      t("初识工坊", "Welcome to the workshop"), t("零件之间", "Between the parts"),
      t("完整收藏", "A complete collection"),
    ]
    for chapter in 0..<3 {
      heading("0\(chapter+1)  " + chapters[chapter])
      for number in (chapter * 12 + 1)...(chapter * 12 + 12) {
        let level = context.level(number)
        let best = context.save.best[level.id]
        let locked = number > context.save.unlocked
        let title =
          "\(locked ? "◌" : best != nil ? "✓" : "○")  \(number). " + context.toyName(level.toy)
          + " · \(level.stage)/3" + (best.map { t("\n最佳 \($0) 步", "\nBest: \($0) moves") } ?? "")
        add(
          WorkshopStyle.button(title) { [weak self] in
            guard let self else { return }
            if locked {
              self.notice(
                self.t("尚未解锁", "Locked"),
                self.t("请先完成第 \(number-1) 关。", "Complete level \(number-1) first."))
            } else {
              self.openGame(level)
            }
          })
      }
    }
  }
}

@MainActor final class LirtrilnerCollectionViewController: LirtrilnerPage {
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    clear()
    title = t("修复收藏", "Collection")
    heading(
      t("值得珍藏的故事", "Stories worth keeping"),
      subtitle: t(
        "修复收藏 \(context.save.collectionCount)/12 · 每件玩具需要三个维修阶段。",
        "Collection \(context.save.collectionCount)/12 · Three repair stages bring each toy back to life."
      ))
    for toy in 0..<12 {
      let stages = context.save.stages(toy)
      let art = LirtrilnerToyView()
      art.toy = toy
      art.stage = stages
      art.heightAnchor.constraint(equalToConstant: 190).isActive = true
      art.accessibilityLabel = context.toyName(toy) + ", \(stages)/3"
      let state =
        stages == 3
        ? t("已修复", "Restored")
        : stages == 0 ? t("待修复", "Awaiting repair") : t("维修中", "Under repair")
      add(
        WorkshopStyle.card([
          art,
          WorkshopStyle.button(context.toyName(toy) + " · " + state + " \(stages)/3") {
            [weak self] in self?.open(LirtrilnerToyDetailViewController(toy: toy))
          },
        ]))
    }
  }
}

@MainActor final class LirtrilnerToyDetailViewController: LirtrilnerPage {
  let toy: Int
  init(toy: Int) {
    self.toy = toy
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  override func viewDidLoad() {
    super.viewDidLoad()
    title = context.toyName(toy)
    let stage = context.save.stages(toy)
    let art = LirtrilnerToyView()
    art.toy = toy
    art.stage = stage
    art.accessibilityLabel = context.toyName(toy)
    art.heightAnchor.constraint(equalToConstant: 300).isActive = true
    add(art)
    heading(context.toyName(toy), subtitle: t("本件维修 \(stage)/3", "Repair progress \(stage)/3"))
    let zh = [
      "它曾每天守在窗边，向路过的人挥手。装好最后一枚齿轮，小小的勇气又开始前进。", "车厢里装着一张没有终点的车票。熟悉的车轮声，带我们回到第一次出发。",
      "一圈又一圈，旋律收藏着午后的阳光。让每一颗音符回到它的位置。", "它梦想飞过屋顶。轻轻转动螺旋桨，整个工作台就成了天空。", "走得慢也没关系。黄色的小家伙，总会找到回家的方向。",
      "它拍不到真正的照片，却装着许多真实的笑容。咔嚓，又是美好的一天。", "红色车身上的擦痕，是它最珍贵的旅行记录。下一程，从工坊开始。",
      "它把每一次摇摆都当作舞台。音乐响起，害羞的小熊也会跳舞。", "咚，咚，哒！节拍恢复了，工坊的每一个角落都有了精神。",
      "没有跑远过，却陪伴了许多冒险。摇一摇，就能抵达想象中的草原。", "一对会转的轮子，一条翘起的尾巴。它已经准备好，再陪你走一小段路。",
      "每个小座舱都有一扇窗。慢慢转动，世界会在你眼前重新展开。",
    ]
    let en = [
      "It used to wave from the window every morning. One final gear brings its little courage back to life.",
      "A ticket with no destination waits in its carriage. Familiar wheels bring back the joy of a first journey.",
      "Round and round, its melody keeps a little afternoon sunshine. Every note has a place to return to.",
      "It dreams of flying over the rooftops. Spin its propeller and the workbench becomes a sky.",
      "There is no need to hurry. This little yellow traveler always finds its way home.",
      "It cannot take real photos, but it holds many real smiles. Click! Another lovely day.",
      "Every scratch on its red body tells a story. The next trip begins at the workshop.",
      "Every sway is a performance. When the music starts, even a shy bear can dance.",
      "Tap, tap, tum! Its steady rhythm wakes up every corner of the workshop.",
      "It has never traveled far, yet shared so many adventures. One gentle rock opens a world of grassy fields.",
      "Two rolling wheels and a cheerful tail. It is ready to walk beside you once again.",
      "Every little cabin has a window. Turn it gently, and watch the world unfold again.",
    ]
    add(WorkshopStyle.card([WorkshopStyle.label(t(zh[toy], en[toy]), size: 18)]))
    for stageIndex in 1...3 {
      let n = toy * 3 + stageIndex
      let best = context.save.best[String(format: "story-%02d", n)]
      add(
        WorkshopStyle.label(
          t("第 \(n) 关 · ", "Level \(n) · ")
            + (best.map { t("完成，最佳 \($0) 步", "Complete, best \($0) moves") }
              ?? t("等待维修", "Awaiting repair")),
          size: 16))
    }
    if stage == 3 {
      add(
        WorkshopStyle.button(t("再动一次", "Play restoration"), symbol: "play.fill") { art.celebrate() }
      )
    } else {
      add(
        WorkshopStyle.label(
          t(
            "完成第 \(toy*3+1)～\(toy*3+3) 关即可加入收藏。",
            "Complete levels \(toy*3+1)–\(toy*3+3) to add this toy to your collection."),
          color: WorkshopStyle.muted))
    }
  }
}

@MainActor final class LirtrilnerResultViewController: LirtrilnerPage {
  let level: LevelDefinition
  let session: GameSession
  init(level: LevelDefinition, session: GameSession) {
    self.level = level
    self.session = session
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.hidesBackButton = true
    let finished = level.stage == 3 && !level.daily
    heading(
      level.daily
        ? t("今日委托完成", "Daily repair complete")
        : finished ? t("它又动起来了", "Back to life!") : t("维修进行中", "A little closer to life"),
      subtitle: level.daily
        ? t("每日挑战不会增加主线或收藏。", "Daily repairs do not change story progress or collections.")
        : [
          t("检查组装完成", "Assembly checked"), t("核心维修完成", "Core mechanism repaired"),
          t("试运行完成", "Test run complete"),
        ][level.stage - 1])
    let art = LirtrilnerToyView()
    art.toy = level.toy
    art.stage = level.daily ? 3 : level.stage
    art.heightAnchor.constraint(equalToConstant: 270).isActive = true
    art.accessibilityLabel = context.toyName(level.toy)
    add(art)
    if finished { art.celebrate() }
    add(
      WorkshopStyle.card([
        WorkshopStyle.label(context.toyName(level.toy), size: 24, weight: .bold),
        WorkshopStyle.label(
          t(
            "使用步数 \(level.moveLimit-session.state.remaining) · 交付零件 \(session.state.orders.reduce(0){$0+$1.delivered})",
            "Moves used \(level.moveLimit-session.state.remaining) · Parts delivered \(session.state.orders.reduce(0){$0+$1.delivered})"
          )),
        WorkshopStyle.label(
          t(
            "主线进度 \(context.save.completedCount)/36\n修复收藏 \(context.save.collectionCount)/12",
            "Story \(context.save.completedCount)/36\nCollection \(context.save.collectionCount)/12"
          ), color: WorkshopStyle.muted),
      ]))
    if !level.daily && level.number < 36 {
      add(
        WorkshopStyle.button(
          finished ? t("下一件玩具", "Next toy") : t("继续维修", "Continue repair"), symbol: "arrow.right",
          primary: true
        ) { [weak self] in
          guard let self else { return }
          let next = self.context.level(self.level.number + 1)
          let game = LirtrilnerGameViewController(
            level: next, session: GameSession(state: BoardEngine.initial(next)))
          var pages = self.navigationController?.viewControllers ?? []
          pages.removeLast()
          pages.append(game)
          self.navigationController?.setViewControllers(pages, animated: true)
        })
    } else if !level.daily {
      add(
        WorkshopStyle.button(t("查看全部收藏", "See your collection"), primary: true) { [weak self] in
          self?.open(LirtrilnerCollectionViewController())
        })
    }
    add(
      WorkshopStyle.button(t("返回工坊", "Back to workshop"), symbol: "house") { [weak self] in
        self?.navigationController?.popToRootViewController(animated: true)
      })
  }
}

@MainActor final class LirtrilnerDailyViewController: LirtrilnerPage {
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    render()
    NotificationCenter.default.addObserver(
      self, selector: #selector(render), name: UIApplication.didBecomeActiveNotification,
      object: nil)
  }
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(
      self, name: UIApplication.didBecomeActiveNotification, object: nil)
  }
  @objc private func render() {
    clear()
    title = t("每日挑战", "Daily Challenge")
    let key = DailySchedule.key(Date())
    let id = context.save.dailySelection[key]
    let level =
      id.flatMap { value in context.levels.first { $0.id == value } }
      ?? context.level(DailySchedule.number(key), daily: true)
    heading(
      t("给今天一份小委托", "A little repair for today"),
      subtitle: "\(key) · "
        + t("题目 \(level.number)/30 · 题库循环", "Puzzle \(level.number)/30 · Rotating pool"))
    let art = LirtrilnerToyView()
    art.toy = level.toy
    art.stage = 1
    art.heightAnchor.constraint(equalToConstant: 230).isActive = true
    art.accessibilityLabel = context.toyName(level.toy)
    add(art)
    add(
      WorkshopStyle.label(
        t(
          "30 道固定谜题，按设备本地公历日期循环。昨天未完成的委托仍可继续，成绩归属原日期。",
          "30 fixed puzzles rotate by your device’s local calendar date. Unfinished repairs keep their original date."
        ), color: WorkshopStyle.muted))
    if let old = context.save.daily, old.dateKey != key, old.state.status != .won,
      let oldLevel = context.levels.first(where: { $0.id == old.state.levelID })
    {
      add(
        WorkshopStyle.button(
          t("继续 \(old.dateKey ?? "") 的挑战", "Continue repair from \(old.dateKey ?? "")"),
          symbol: "arrow.uturn.backward"
        ) { [weak self] in self?.openGame(oldLevel, date: old.dateKey) })
    }
    add(
      WorkshopStyle.button(
        context.save.dailyBest[key] == nil
          ? t("开始今日挑战", "Start today’s repair") : t("今日已完成 · 再次挑战", "Completed today · Play again"),
        symbol: "calendar", primary: true
      ) { [weak self] in
        guard let self else { return }
        let start = {
          self.context.save.dailySelection[key] = level.id
          self.context.persist()
          self.openGame(level, date: key)
        }
        if let old = self.context.save.daily, old.dateKey != key, old.state.status != .won {
          self.confirm(
            self.t("开始新的委托？", "Start today’s repair?"),
            self.t(
              "这会替换未完成的旧每日局，主线进度不受影响。",
              "This replaces the unfinished daily puzzle. Story progress stays."), action: start)
        } else {
          start()
        }
      })
    heading(t("维修记录", "Repair journal"))
    if context.save.dailyBest.isEmpty {
      add(
        WorkshopStyle.label(
          t("完成第一道每日委托，就会在这里留下记录。", "Complete your first daily repair to start your journal."),
          color: WorkshopStyle.muted))
    }
    for date in context.save.dailyBest.keys.sorted().reversed().prefix(30) {
      add(
        WorkshopStyle.label(
          "✓ \(date) · "
            + t("\(context.save.dailyBest[date]!) 步", "\(context.save.dailyBest[date]!) moves")))
    }
  }
}
