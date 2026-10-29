#if DEBUG
  import UIKit

  // A development-only render audit, excluded from Release. It instantiates the
  // real pages using engine-verified positions. No OS input or synthetic gestures.
  @MainActor enum LirtrilnerRenderAudit {
    static func run(window: UIWindow) {
      guard let navigation = window.rootViewController as? UINavigationController else { return }
      let context = LirtrilnerContext.shared
      guard context.contentError == nil else { return }
      let original = context.save
      let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("RenderAudit")
      try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
      var jobs: [(String, () -> UIViewController)] = []
      var report: [String] = []
      for language in ["zh", "en"] {
        func state(completed: Int) {
          context.save = SaveEnvelope()
          context.save.settings.language = language
          context.save.settings.music = false
          context.save.tutorialSeen = true
          for number in 1...max(1, completed) where number <= completed {
            let level = context.level(number)
            var session = GameSession(state: BoardEngine.initial(level))
            for action in level.reference { _ = session.apply(action, level: level) }
            context.save.record(session, level: level)
          }
        }
        jobs.append(
          (
            "\(language)-workshop",
            {
              state(completed: 3)
              let home = LirtrilnerWorkshopViewController()
              home.firstAppearance = false
              return home
            }
          ))
        jobs.append(
          (
            "\(language)-workshop-robot",
            {
              state(completed: 0)
              let home = LirtrilnerWorkshopViewController()
              home.firstAppearance = false
              return home
            }
          ))
        for number in [1, 4, 36] {
          jobs.append(
            (
              "\(language)-level-\(number)",
              {
                state(completed: number - 1)
                let level = context.level(number)
                return LirtrilnerGameViewController(
                  level: level, session: GameSession(state: BoardEngine.initial(level)))
              }
            ))
        }
        jobs.append(
          (
            "\(language)-delivery",
            {
              state(completed: 0)
              let level = context.level(1)
              var session = GameSession(state: BoardEngine.initial(level))
              _ = session.apply(level.reference[0], level: level)
              return LirtrilnerGameViewController(level: level, session: session)
            }
          ))
        for number in [1, 3, 36] {
          jobs.append(
            (
              "\(language)-result-\(number)",
              {
                state(completed: number)
                let level = context.level(number)
                var session = GameSession(state: BoardEngine.initial(level))
                for action in level.reference { _ = session.apply(action, level: level) }
                return LirtrilnerResultViewController(level: level, session: session)
              }
            ))
        }
        jobs.append(
          (
            "\(language)-collection",
            {
              state(completed: 36)
              return LirtrilnerCollectionViewController()
            }
          ))
        jobs.append(
          (
            "\(language)-daily",
            {
              state(completed: 3)
              return LirtrilnerDailyViewController()
            }
          ))
        jobs.append(
          (
            "\(language)-settings",
            {
              state(completed: 3)
              return LirtrilnerSettingsViewController()
            }
          ))
        jobs.append(
          (
            "\(language)-rules",
            {
              state(completed: 3)
              return LirtrilnerRulesViewController()
            }
          ))
        jobs.append(
          (
            "\(language)-privacy",
            {
              state(completed: 3)
              return LirtrilnerInformationViewController(privacy: true)
            }
          ))
        jobs.append(
          (
            "\(language)-support",
            {
              state(completed: 3)
              return LirtrilnerInformationViewController(privacy: false)
            }
          ))
        for toy in 0..<12 {
          jobs.append(
            (
              "\(language)-toy-\(toy+1)",
              {
                state(completed: 36)
                return LirtrilnerToyDetailViewController(toy: toy)
              }
            ))
        }
      }
      func next(_ index: Int) {
        guard index < jobs.count else {
          context.save = original
          try? report.joined(separator: "\n").write(
            to: output.appendingPathComponent("report.txt"), atomically: true, encoding: .utf8)
          print("LIRTRILNER_RENDER_AUDIT_COMPLETE \(jobs.count) pages")
          return
        }
        let (name, make) = jobs[index]
        let page = make()
        navigation.setViewControllers([page], animated: false)
        window.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
          window.layoutIfNeeded()
          let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
          let image = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
          }
          try? image.pngData()?.write(to: output.appendingPathComponent(name + ".png"))
          var ambiguous = 0
          func inspect(_ view: UIView) {
            if view.hasAmbiguousLayout { ambiguous += 1 }
            view.subviews.forEach(inspect)
          }
          inspect(page.view)
          report.append(
            "\(name): \(Int(window.bounds.width))x\(Int(window.bounds.height)) pt, ambiguousViews=\(ambiguous)"
          )
          next(index + 1)
        }
      }
      next(0)
    }
  }
#endif
