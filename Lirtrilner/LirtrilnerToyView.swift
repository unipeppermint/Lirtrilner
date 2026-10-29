import UIKit

/// Separate scenery and transparent toy assets keep the artwork independent of
/// labels, repair state and celebration animations.
@MainActor final class LirtrilnerToyView: UIView {
  var toy = 0 { didSet { updateArtwork() } }
  var stage = 0 { didSet { updateArtwork() } }
  var workshop = true {
    didSet {
      backdrop.isHidden = !workshop
      backgroundColor = workshop ? WorkshopStyle.wood : .clear
    }
  }

  private let backdrop = UIImageView(image: UIImage(named: "Lirtrilner-workshop-v2"))
  private let character = UIImageView()
  private let shadow = UIView()
  private let shadowGradient = CAGradientLayer()
  private let repairTag = UILabel()
  private let names = [
    "robot", "train", "carousel", "plane", "duck", "camera",
    "car", "bear", "drummer", "horse", "dog", "ferris",
  ]

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = WorkshopStyle.wood
    layer.cornerRadius = 24
    layer.cornerCurve = .continuous
    clipsToBounds = true
    isAccessibilityElement = true
    accessibilityTraits = .image
    backdrop.contentMode = .scaleAspectFill
    character.contentMode = .scaleAspectFit
    shadowGradient.type = .radial
    shadowGradient.colors = [
      UIColor(hex: 0x50311E).withAlphaComponent(0.22).cgColor,
      UIColor(hex: 0x50311E).withAlphaComponent(0).cgColor,
    ]
    shadowGradient.startPoint = CGPoint(x: 0.5, y: 0.5)
    shadowGradient.endPoint = CGPoint(x: 1, y: 1)
    shadow.layer.addSublayer(shadowGradient)
    repairTag.font = WorkshopStyle.font(12, weight: .bold)
    repairTag.textColor = WorkshopStyle.ink
    repairTag.textAlignment = .center
    repairTag.backgroundColor = WorkshopStyle.cream.withAlphaComponent(0.96)
    repairTag.layer.cornerRadius = 12
    repairTag.clipsToBounds = true
    [backdrop, shadow, character, repairTag].forEach(addSubview)
    updateArtwork()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()
    backdrop.frame = bounds
    let height = bounds.height * 0.91
    let width = min(bounds.width * 0.86, height * 1.13)
    character.frame = CGRect(
      x: (bounds.width - width) / 2, y: bounds.height * 0.025, width: width, height: height)
    shadow.frame = CGRect(
      x: bounds.width * 0.26, y: bounds.height * 0.81, width: bounds.width * 0.48, height: 28)
    shadowGradient.frame = shadow.bounds
    repairTag.frame = CGRect(x: 12, y: bounds.height - 36, width: 114, height: 25)
  }

  private func updateArtwork() {
    guard names.indices.contains(toy) else { return }
    character.image = UIImage(named: "Lirtrilner-\(names[toy])-v2")
    character.alpha = stage == 0 ? 0.82 : 1
    let context = LirtrilnerContext.shared
    repairTag.text =
      stage == 3
      ? context.text("✓ 已修复", "✓ Restored")
      : stage == 0
        ? context.text("待修复  0/3", "To repair  0/3")
        : context.text("维修中  \(stage)/3", "Repair  \(stage)/3")
    repairTag.backgroundColor =
      stage == 3
      ? UIColor(hex: 0xE2F0D8) : WorkshopStyle.cream.withAlphaComponent(0.96)
    setNeedsLayout()
  }

  func celebrate() {
    guard !UIAccessibility.isReduceMotionEnabled else { return }
    character.layer.removeAllAnimations()
    let bounce = CAKeyframeAnimation(keyPath: "transform.translation.y")
    bounce.values = [0, -9, 0, -5, 0]
    bounce.keyTimes = [0, 0.25, 0.5, 0.75, 1]
    bounce.duration = 1.0
    let tilt = CAKeyframeAnimation(keyPath: "transform.rotation.z")
    tilt.values = [0, -0.04, 0.035, -0.02, 0]
    tilt.duration = 1.0
    character.layer.add(bounce, forKey: "restorationBounce")
    character.layer.add(tilt, forKey: "restorationTilt")
  }
}
