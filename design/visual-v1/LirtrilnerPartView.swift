import UIKit

@MainActor final class LirtrilnerPartView: UIView {
  var part: Part? { didSet { setNeedsDisplay() } }
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    isAccessibilityElement = false
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  override func draw(_ rect: CGRect) {
    guard let part, let context = UIGraphicsGetCurrentContext() else { return }
    let width = min(bounds.width - 10, bounds.height - 8)
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let color = part.kind == .gear ? WorkshopStyle.coral : UIColor(hex: 0x276E5A)
    context.setShadow(
      offset: CGSize(width: 0, height: 2), blur: 2,
      color: UIColor.black.withAlphaComponent(0.18).cgColor)
    color.setFill()
    if part.kind == .gear {
      let path = UIBezierPath()
      for i in 0..<48 {
        let angle = CGFloat(i) * .pi / 24
        let radius = width * (i % 4 == 0 || i % 4 == 3 ? 0.40 : 0.49)
        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
      }
      path.close()
      path.fill()
      context.setShadow(offset: .zero, blur: 0)
      let ring = UIBezierPath(
        ovalIn: CGRect(
          x: center.x - width * 0.31, y: center.y - width * 0.31, width: width * 0.62,
          height: width * 0.62))
      WorkshopStyle.cream.withAlphaComponent(0.65).setStroke()
      ring.lineWidth = 1.3
      ring.stroke()
    } else {
      UIBezierPath(
        roundedRect: CGRect(
          x: center.x - width * 0.34, y: center.y - width * 0.37, width: width * 0.68,
          height: width * 0.80), cornerRadius: width * 0.11
      ).fill()
      UIBezierPath(
        roundedRect: CGRect(
          x: center.x - width * 0.14, y: center.y - width * 0.49, width: width * 0.28,
          height: width * 0.15), cornerRadius: 3
      ).fill()
      context.setShadow(offset: .zero, blur: 0)
      WorkshopStyle.cream.withAlphaComponent(0.4).setFill()
      UIBezierPath(
        roundedRect: CGRect(
          x: center.x - width * 0.27, y: center.y - width * 0.29, width: width * 0.05,
          height: width * 0.55), cornerRadius: 2
      ).fill()
    }
    let text = ["", "I", "II", "III", "IV"][part.level]
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: width * 0.35, weight: .bold),
      .foregroundColor: WorkshopStyle.cream,
    ]
    let size = (text as NSString).size(withAttributes: attributes)
    (text as NSString).draw(
      at: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2),
      withAttributes: attributes)
  }
}
