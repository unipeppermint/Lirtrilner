import UIKit

@MainActor final class LirtrilnerPartView: UIView {
  var part: Part? { didSet { updatePart() } }
  private let artwork = UIImageView()
  private let rank = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    isAccessibilityElement = false
    artwork.contentMode = .scaleAspectFit
    rank.textAlignment = .center
    rank.textColor = WorkshopStyle.cream
    rank.layer.shadowColor = UIColor.black.cgColor
    rank.layer.shadowOpacity = 0.24
    rank.layer.shadowRadius = 0.5
    rank.layer.shadowOffset = CGSize(width: 0, height: 0.5)
    addSubview(artwork)
    addSubview(rank)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()
    artwork.frame = bounds
    let centerY = bounds.height * (part?.kind == .battery ? 0.55 : 0.50)
    rank.frame = CGRect(
      x: 0, y: centerY - bounds.height * 0.2,
      width: bounds.width, height: bounds.height * 0.4)
    let size = min(bounds.width, bounds.height) * 0.31
    let base = UIFont.systemFont(ofSize: size, weight: .semibold)
    rank.font = UIFont(descriptor: base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor,
                       size: size)
  }

  private func updatePart() {
    guard let part else {
      artwork.image = nil
      rank.text = nil
      return
    }
    artwork.image = UIImage(
      named: part.kind == .gear ? "Lirtrilner-gear-v3" : "Lirtrilner-battery-v3")
    rank.text = ["", "I", "II", "III", "IV"][part.level]
    setNeedsLayout()
  }
}
