import UIKit

@MainActor enum WorkshopStyle {
  static let cream = UIColor(hex: 0xFFF7E8)
  static let paper = UIColor(hex: 0xFFFCF5)
  static let ink = UIColor(hex: 0x35271F)
  static let muted = UIColor(hex: 0x746255)
  static let coral = UIColor(hex: 0xB73E2B)
  static let mint = UIColor(hex: 0x78BDA8)
  static let blue = UIColor(hex: 0x405C78)
  static let gold = UIColor(hex: 0xD9A34C)
  static let wood = UIColor(hex: 0xDFC3A1)

  static func font(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
    let base = UIFont.systemFont(ofSize: size, weight: weight)
    let rounded = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
    return UIFontMetrics(forTextStyle: .body).scaledFont(
      for: UIFont(descriptor: rounded, size: size), maximumPointSize: size * 1.6)
  }

  static func label(
    _ text: String, size: CGFloat = 16, weight: UIFont.Weight = .regular, color: UIColor? = nil
  ) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = font(size, weight: weight)
    label.textColor = color ?? ink
    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    return label
  }

  static func button(
    _ title: String, symbol: String? = nil, primary: Bool = false, action: @escaping () -> Void
  ) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.baseBackgroundColor = .clear
    config.background.backgroundColor = .clear
    config.baseForegroundColor = primary ? .white : ink
    config.cornerStyle = .large
    config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
      var value = attributes
      value.font = font(17, weight: .semibold)
      return value
    }
    if let symbol {
      config.image = UIImage(systemName: symbol)
      config.imagePadding = 10
    }
    let button = LirtrilnerRaisedButton(frame: .zero)
    button.primary = primary
    button.configuration = config
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    button.titleLabel?.numberOfLines = 0
    button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
    return button
  }

  static func card(_ views: [UIView], spacing: CGFloat = 12) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: views)
    stack.axis = .vertical
    stack.spacing = spacing
    stack.isLayoutMarginsRelativeArrangement = true
    stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
      top: 18, leading: 18, bottom: 18, trailing: 18)
    stack.backgroundColor = paper
    stack.layer.cornerRadius = 22
    stack.layer.borderColor = wood.withAlphaComponent(0.65).cgColor
    stack.layer.borderWidth = 1
    stack.layer.shadowColor = UIColor(hex: 0x8A5B30).cgColor
    stack.layer.shadowOpacity = 0.08
    stack.layer.shadowRadius = 5
    stack.layer.shadowOffset = CGSize(width: 0, height: 3)
    return stack
  }
}

extension UIColor {
  convenience init(hex: UInt32) {
    self.init(
      red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
      blue: CGFloat(hex & 255) / 255, alpha: 1)
  }
}

@MainActor final class LirtrilnerContext {
  static let shared = LirtrilnerContext()
  var levels: [LevelDefinition] = []
  var save: SaveEnvelope
  let store: SaveStore
  var recovery: String?
  var contentError: String?
  var saveError: String?
  var language: String {
    save.settings.language == "system"
      ? (Locale.preferredLanguages.first?.hasPrefix("zh") == true ? "zh" : "en")
      : save.settings.language
  }

  private init() {
    let directory = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent(
        "Lirtrilner")
    store = SaveStore(directory: directory)
    let loaded = store.load()
    save = loaded.0
    recovery = loaded.1
    do {
      guard let url = Bundle.main.url(forResource: "Lirtrilner-levels", withExtension: "json")
      else { throw ContentError(description: "Missing content") }
      levels = try LevelRepository.load(Data(contentsOf: url))
      for daily in [false, true] {
        if let session = daily ? save.daily : save.story {
          do {
            guard
              let level = levels.first(where: {
                $0.id == session.state.levelID && $0.daily == daily
              })
            else { throw ContentError(description: "Unknown level") }
            try LevelRepository.validate(session.state, level: level)
            guard session.history.count <= 100 else {
              throw ContentError(description: "History too long")
            }
            for state in session.history { try LevelRepository.validate(state, level: level) }
          } catch {
            if daily { save.daily = nil } else { save.story = nil }
            recovery = "session"
          }
        }
      }
    } catch { contentError = String(describing: error) }
  }

  func text(_ chinese: String, _ english: String) -> String { language == "zh" ? chinese : english }
  func persist() {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-LirtrilnerRenderAudit") { return }
    #endif
    save.revision += 1
    store.write(save) { error in
      Task { @MainActor in
        self.saveError = error
        NotificationCenter.default.post(name: .lirtrilnerSaveChanged, object: nil)
      }
    }
  }
  func level(_ number: Int, daily: Bool = false) -> LevelDefinition {
    levels.first { $0.number == number && $0.daily == daily }!
  }
  func toyName(_ toy: Int) -> String {
    let zh = [
      "发条机器人", "小火车", "旋转音乐盒", "螺旋桨飞机", "发条小鸭", "玩具相机", "小汽车", "跳舞小熊", "小鼓手", "木马", "机械小狗", "小小摩天轮",
    ]
    let en = [
      "Clockwork Robot", "Little Train", "Music Carousel", "Propeller Plane", "Wind-up Duck",
      "Toy Camera", "Little Car", "Dancing Bear", "Little Drummer", "Rocking Horse",
      "Mechanical Pup", "Ferris Wheel",
    ]
    return language == "zh" ? zh[toy] : en[toy]
  }
  func partName(_ kind: PartKind, _ level: Int) -> String {
    text(kind == .gear ? "齿轮" : "电池", kind == .gear ? "Gear" : "Battery") + " "
      + ["", "I", "II", "III", "IV"][level]
  }
}

extension Notification.Name {
  static let lirtrilnerSaveChanged = Notification.Name("LirtrilnerSaveChanged")
}

@MainActor class LirtrilnerPage: UIViewController {
  let context = LirtrilnerContext.shared
  let stack = UIStackView()
  let scroll = UIScrollView()
  var scrollBottom: NSLayoutConstraint!
  func t(_ zh: String, _ en: String) -> String { context.text(zh, en) }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = WorkshopStyle.cream
    scroll.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scroll)
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(stack)
    scrollBottom = scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollBottom,
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
      stack.leadingAnchor.constraint(
        equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(
        equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
    ])
  }
  func clear() { stack.arrangedSubviews.forEach { $0.removeFromSuperview() } }
  func add(_ view: UIView) { stack.addArrangedSubview(view) }
  func heading(_ title: String, subtitle: String? = nil) {
    add(WorkshopStyle.label(title, size: 30, weight: .bold))
    if let subtitle { add(WorkshopStyle.label(subtitle, size: 15, color: WorkshopStyle.muted)) }
  }
  func notice(_ title: String, _ message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: t("知道了", "OK"), style: .default))
    present(alert, animated: true)
  }
  func confirm(_ title: String, _ message: String, action: @escaping () -> Void) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: t("取消", "Cancel"), style: .cancel))
    alert.addAction(UIAlertAction(title: t("确认", "Confirm"), style: .destructive) { _ in action() })
    present(alert, animated: true)
  }
  func open(_ page: UIViewController) {
    navigationController?.pushViewController(page, animated: true)
  }
  func openGame(_ level: LevelDefinition, date: String? = nil, resume: Bool = true) {
    let saved = level.daily ? context.save.daily : context.save.story
    let session: GameSession
    if resume, let saved, saved.state.levelID == level.id, saved.state.status != .won,
      !level.daily || saved.dateKey == date
    {
      session = saved
    } else {
      session = GameSession(state: BoardEngine.initial(level), dateKey: date)
    }
    open(LirtrilnerGameViewController(level: level, session: session))
  }
}
