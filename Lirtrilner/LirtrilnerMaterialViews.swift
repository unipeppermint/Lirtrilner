import UIKit

/// Native highlights and shadows carry the same enamel-and-paper language as
/// the illustrations while preserving dynamic titles and accessibility.
@MainActor final class LirtrilnerRaisedButton: UIButton {
  var primary = false {
    didSet { updateMaterial() }
  }
  private let material = CAGradientLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    // Keep the material behind the configuration-backed button's content.
    material.zPosition = -1
    layer.insertSublayer(material, at: 0)
    layer.cornerRadius = 22
    layer.cornerCurve = .continuous
    layer.borderWidth = 1.5
    layer.shadowOffset = CGSize(width: 0, height: 3)
    layer.shadowRadius = 3
    updateMaterial()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override var isHighlighted: Bool {
    didSet {
      material.opacity = isHighlighted ? 0.78 : 1
      layer.shadowOpacity = isHighlighted ? 0.05 : 0.16
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    material.frame = bounds
    // The fill and outer border must use the same corner geometry.
    // A circular fill leaves crescent gaps inside a continuous border.
    material.cornerRadius = layer.cornerRadius
    material.cornerCurve = layer.cornerCurve
    CATransaction.commit()
    layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 22).cgPath
  }

  private func updateMaterial() {
    material.colors =
      primary
      ? [UIColor(hex: 0xCD5037).cgColor, UIColor(hex: 0xAC3020).cgColor]
      : [UIColor(hex: 0xFFFCF4).cgColor, UIColor(hex: 0xF3DFC1).cgColor]
    material.startPoint = CGPoint(x: 0.5, y: 0)
    material.endPoint = CGPoint(x: 0.5, y: 1)
    layer.borderColor = (primary ? UIColor(hex: 0xF18B69) : UIColor(hex: 0xE4C8A0)).cgColor
    layer.shadowColor = UIColor(hex: 0x6C3D21).cgColor
    layer.shadowOpacity = 0.16
  }
}
