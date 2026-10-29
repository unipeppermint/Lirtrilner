import UIKit

@MainActor final class LirtrilnerSettingsViewController: LirtrilnerPage {
  override func viewDidLoad() {
    super.viewDidLoad()
    render()
  }
  func render() {
    clear()
    title = t("设置", "Settings")
    heading(t("让工坊更合心意", "Make yourself at home"))
    toggle(t("背景音乐", "Music"), value: context.save.settings.music) { [weak self] in
      self?.context.save.settings.music = $0
    }
    toggle(t("音效", "Sound effects"), value: context.save.settings.sound) { [weak self] in
      self?.context.save.settings.sound = $0
    }
    toggle(t("触觉反馈", "Haptics"), value: context.save.settings.haptics) { [weak self] in
      self?.context.save.settings.haptics = $0
    }
    add(
      WorkshopStyle.button(t("语言 · 简体中文", "Language · English"), symbol: "globe") { [weak self] in
        guard let self else { return }
        let alert = UIAlertController(
          title: self.t("语言", "Language"), message: nil, preferredStyle: .alert)
        for (code, title) in [
          ("system", self.t("跟随系统", "System")), ("zh", "简体中文"), ("en", "English"),
        ] {
          alert.addAction(
            UIAlertAction(title: title, style: .default) { _ in
              self.context.save.settings.language = code
              self.context.persist()
              self.render()
            })
        }
        alert.addAction(UIAlertAction(title: self.t("取消", "Cancel"), style: .cancel))
        self.present(alert, animated: true)
      })
    add(
      WorkshopStyle.button(t("规则与新手教学", "Rules & tutorial"), symbol: "book") { [weak self] in
        self?.open(LirtrilnerRulesViewController())
      })
    add(
      WorkshopStyle.button(t("隐私说明", "Privacy"), symbol: "hand.raised") { [weak self] in
        self?.open(LirtrilnerInformationViewController(privacy: true))
      })
    add(
      WorkshopStyle.button(t("帮助与支持", "Help & support"), symbol: "questionmark.circle") {
        [weak self] in self?.open(LirtrilnerInformationViewController(privacy: false))
      })
    if context.saveError != nil {
      add(
        WorkshopStyle.label(
          t("暂未保存：", "Not saved: ") + (context.saveError ?? ""), color: WorkshopStyle.coral))
      add(WorkshopStyle.button(t("重试保存", "Retry save")) { [weak self] in self?.context.persist() })
    }
    add(
      WorkshopStyle.button(t("重置全部进度", "Reset all progress"), symbol: "trash") { [weak self] in
        guard let self else { return }
        self.confirm(
          self.t("删除全部进度？", "Delete all progress?"),
          self.t(
            "主线、收藏、每日记录、当前关卡及备份都会删除。此操作无法撤销。设置将保留。",
            "This deletes story progress, toys, daily records, active puzzles and the backup. This cannot be undone. Settings are kept."
          )
        ) {
          var fresh = SaveEnvelope()
          fresh.settings = self.context.save.settings
          do {
            try self.context.store.reset(fresh)
            self.context.save = fresh
            self.context.saveError = nil
            self.navigationController?.popToRootViewController(animated: true)
          } catch { self.notice(self.t("重置失败", "Reset failed"), error.localizedDescription) }
        }
      })
    let version =
      Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    add(
      WorkshopStyle.label(
        t("发条修理铺", "Clockwork Toy Workshop") + " · \(version) (\(build))\n"
          + t(
            "免费 · 无广告 · 无内购\n遵循系统减弱动态效果设置。",
            "Free · No ads · No in-app purchases\nFollows the system Reduce Motion setting."),
        size: 14, color: WorkshopStyle.muted))
  }
  private func toggle(_ title: String, value: Bool, change: @escaping (Bool) -> Void) {
    let label = WorkshopStyle.label(title, size: 18, weight: .semibold)
    let control = UISwitch()
    control.isOn = value
    control.onTintColor = WorkshopStyle.coral
    control.accessibilityLabel = title
    control.addAction(
      UIAction { [weak self, weak control] _ in
        change(control?.isOn ?? false)
        self?.context.persist()
        LirtrilnerAudioService.shared.configure()
      }, for: .valueChanged)
    let row = UIStackView(arrangedSubviews: [label, control])
    row.spacing = 12
    row.alignment = .center
    add(WorkshopStyle.card([row]))
  }
}

@MainActor final class LirtrilnerRulesViewController: LirtrilnerPage {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = t("规则手册", "Rule book")
    let sections: [(String, String, String, String)] = [
      (
        "01  只动一条轨道", "01  One track at a time", "从任意格起手滑动。向左或右只移动这一行；向上或下只移动这一列。障碍将轨道分成互不穿越的段。",
        "Start on any cell. Left/right moves its row; up/down moves its column. Obstacles split a track into separate sections."
      ),
      (
        "02  合并到刚刚好", "02  Just the right level",
        "相同类型、相同等级才能合并。I + I → II，II + II → III，III + III → IV。IV 不再合并；新零件在同次滑动中不会再次合并。",
        "Only identical types and levels merge. I + I → II, II + II → III, III + III → IV. Level IV cannot merge; a newly merged part cannot merge again in the same move."
      ),
      (
        "03  亲手交付", "03  Deliver by hand",
        "金框机器人是交付格。零件停在那里且精确匹配订单后，轻点交付。交付不扣步数；最后一步后仍可交付。高一级不等于更合适。",
        "The gold robot cell is delivery. Match an order’s type and level exactly, then tap to deliver. Delivery costs no moves, even after the last slide. A higher level is not a substitute."
      ),
      (
        "04  可预测的补给", "04  Predictable supplies",
        "每次有效滑动后最多投放一枚。蓝框入口堵塞时，同一枚等待，不累计投放机会。交付清空入口后会重试等待补给一次。",
        "Each valid slide attempts one supply. If the blue entrance is blocked, that same part waits; attempts do not accumulate. Delivery retries a waiting supply once."
      ),
      (
        "05  放心尝试", "05  Room to experiment",
        "无变化不扣步；免费提示只提供已找到完整通关路线的下一步。搜索暂未找到路线不代表无解。可撤销最近 100 次操作或重开，通关结算后不能撤销。",
        "Unchanged tracks cost no moves. Free hints show a next action only after finding a complete solution. An unknown result does not prove a puzzle impossible. Undo up to 100 actions, or restart. Completed results cannot be undone."
      ),
      (
        "06  三阶段的故事", "06  Three stages, one story",
        "36 关对应 12 件玩具，每件三个阶段。只有第三阶段完成后才增加收藏。每日挑战独立保存，30 题按本地日期循环。",
        "36 story puzzles restore 12 toys in three stages each. Only completing all three stages adds a toy. Daily repairs have separate saves and cycle through 30 puzzles by local date."
      ),
      (
        "07  无障碍操作", "07  Accessible controls",
        "开启 VoiceOver 后，每格会读出坐标、零件、等级和交付状态。使用格子的自定义操作菜单选择滑动方向；也可点击交付按钮。",
        "With VoiceOver, cells announce coordinates, parts, levels and delivery information. Use each cell’s custom actions to choose a direction, and the Deliver button to deliver."
      ),
    ]
    for item in sections {
      add(
        WorkshopStyle.card([
          WorkshopStyle.label(t(item.0, item.1), size: 21, weight: .bold),
          WorkshopStyle.label(t(item.2, item.3)),
        ]))
    }
    add(
      WorkshopStyle.button(
        t("重看第 1 关教学", "Replay the first tutorial"), symbol: "play", primary: true
      ) { [weak self] in
        guard let self else { return }
        self.confirm(
          self.t("进入教学？", "Replay tutorial?"),
          self.t(
            "将替换当前主线未完成局，已完成记录与收藏保留。",
            "This replaces your unfinished story puzzle. Completed results and collection stay.")
        ) { self.openGame(self.context.level(1), resume: false) }
      })
  }
}

@MainActor final class LirtrilnerInformationViewController: LirtrilnerPage {
  let privacy: Bool
  init(privacy: Bool) {
    self.privacy = privacy
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  override func viewDidLoad() {
    super.viewDidLoad()
    title = privacy ? t("隐私说明", "Privacy") : t("帮助与支持", "Help & support")
    if privacy {
      heading(t("你的工坊，保存在本机", "Your workshop stays on your device"))
      add(
        WorkshopStyle.card([
          WorkshopStyle.label(
            t(
              "发条修理铺不创建账号，不接入广告、第三方统计或追踪服务，核心玩法不向开发者服务器发送数据。\n\n关卡成绩、收藏、未完成局和设置保存在本设备的应用目录中。系统设备备份可能包含这些数据。本应用不提供跨设备云同步。\n\n可在设置中选择“重置全部进度”删除游戏记录及备份。卸载应用可能导致本地进度丢失。应用不请求定位、相机、麦克风、通讯录或照片权限。",
              "Clockwork Toy Workshop has no accounts, advertising, analytics or tracking services. Core gameplay sends no data to developer servers.\n\nPuzzle results, collected toys, active games and settings are stored in this app’s directory on your device. System device backups may include these files. The app does not provide cross-device cloud sync.\n\nUse Reset all progress in Settings to delete game records and their backup. Uninstalling may erase local progress. The app does not request location, camera, microphone, contacts or photo permissions."
            ))
        ]))
    } else {
      heading(t("让维修顺利继续", "Keep your repairs moving"))
      let entries = [
        (
          "无法交付？", "Cannot deliver?", "检查金框交付格上的零件是否与未完成订单的类型和等级完全相同。轻点交付格或“交付零件”按钮。",
          "Check that the part on the gold cell exactly matches an unfinished order. Tap that cell or Deliver part."
        ),
        (
          "补给没有出现？", "A supply did not appear?", "入口堵塞时保留原零件等待。移开入口上的零件，再进行有效滑动，或交付入口上的零件。",
          "A blocked entrance keeps the same supply waiting. Clear it and make a valid slide, or deliver the part occupying it."
        ),
        (
          "如何恢复进度？", "How do saves work?",
          "主线和每日局分别自动保存。返回工坊继续即可。存档损坏时应用尝试读取上一份备份并说明恢复情况。设备备份恢复由系统管理。",
          "Story and daily games save separately. Continue from the workshop. If a save is damaged, the app tries its previous backup and reports recovery. Device backup restoration is managed by the system."
        ),
        (
          "没有声音？", "No sound?", "检查设置中的音乐和音效开关，并检查设备静音模式及音量。本应用尊重静音模式。",
          "Check the Music and Sound effects switches, device volume and Silent mode. This app respects Silent mode."
        ),
        (
          "卡住了？", "Stuck?", "使用免费提示、撤销或重开。重开不会删除已获得的收藏。全部核心玩法都可以离线使用。",
          "Try a free hint, undo or restart. Restarting keeps your collected toys. All core gameplay works offline."
        ),
      ]
      for item in entries {
        add(
          WorkshopStyle.card([
            WorkshopStyle.label(t(item.0, item.1), size: 20, weight: .bold),
            WorkshopStyle.label(t(item.2, item.3)),
          ]))
      }
    }
  }
}
