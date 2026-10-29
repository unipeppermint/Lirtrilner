import UIKit

// Original vector illustrations. All twelve toys share the same palette and
// construction language, but have distinct silhouettes and moving components.
@MainActor final class LirtrilnerToyView: UIView {
  var toy = 0 { didSet { setNeedsDisplay() } }
  var stage = 0 { didSet { setNeedsDisplay() } }
  var workshop = true
  private var displayLink: CADisplayLink?
  private var startedAt: CFTimeInterval = 0
  private var tilt: CGFloat = 0
  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
    layer.cornerRadius = 24
    clipsToBounds = true
    isAccessibilityElement = true
    accessibilityTraits = .image
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func celebrate() {
    guard !UIAccessibility.isReduceMotionEnabled else { return }
    displayLink?.invalidate()
    startedAt = 0
    let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  @objc private func tick(_ link: CADisplayLink) {
    if startedAt == 0 { startedAt = link.timestamp }
    let elapsed = link.timestamp - startedAt
    if elapsed > 1.5 || window == nil || UIAccessibility.isReduceMotionEnabled {
      link.invalidate()
      displayLink = nil
      tilt = 0
    } else {
      tilt = sin(elapsed * 12) * 0.06
    }
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    guard let ctx = UIGraphicsGetCurrentContext() else { return }
    let scale = min(bounds.width / 320, bounds.height / 260)
    ctx.translateBy(x: (bounds.width - 320 * scale) / 2, y: (bounds.height - 260 * scale) / 2)
    ctx.scaleBy(x: scale, y: scale)
    let red = WorkshopStyle.coral
    let cream = WorkshopStyle.cream
    let ink = WorkshopStyle.ink
    let mint = WorkshopStyle.mint
    let blue = WorkshopStyle.blue
    let gold = WorkshopStyle.gold
    func box(
      _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: UIColor,
      _ radius: CGFloat = 10
    ) {
      color.setFill()
      UIBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius)
        .fill()
    }
    func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: UIColor) {
      color.setFill()
      UIBezierPath(ovalIn: CGRect(x: x, y: y, width: w, height: h)).fill()
    }
    func line(_ points: [CGPoint], _ color: UIColor, _ width: CGFloat = 4) {
      guard let first = points.first else { return }
      let p = UIBezierPath()
      p.move(to: first)
      points.dropFirst().forEach { p.addLine(to: $0) }
      p.lineWidth = width
      p.lineCapStyle = .round
      color.setStroke()
      p.stroke()
    }
    func wheel(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat = 19) {
      oval(x - r, y - r, r * 2, r * 2, ink)
      oval(x - r + 5, y - r + 5, r * 2 - 10, r * 2 - 10, gold)
      oval(x - 4, y - 4, 8, 8, cream)
    }
    func eye(_ x: CGFloat, _ y: CGFloat) {
      oval(x - 5, y - 5, 10, 12, ink)
      oval(x - 2, y - 3, 3, 3, .white)
    }
    func face(_ y: CGFloat) {
      eye(141, y)
      eye(179, y)
      let path = UIBezierPath(
        arcCenter: CGPoint(x: 160, y: y + 10), radius: 9, startAngle: 0, endAngle: .pi,
        clockwise: true)
      path.lineWidth = 3
      ink.setStroke()
      path.stroke()
      oval(125, y + 9, 10, 5, red.withAlphaComponent(0.3))
      oval(185, y + 9, 10, 5, red.withAlphaComponent(0.3))
    }
    if workshop {
      box(0, 0, 320, 260, UIColor(hex: 0xF1E2CA), 0)
      box(18, 18, 78, 100, cream, 9)
      line([CGPoint(x: 57, y: 20), CGPoint(x: 57, y: 115)], WorkshopStyle.wood, 4)
      line([CGPoint(x: 20, y: 65), CGPoint(x: 93, y: 65)], WorkshopStyle.wood, 4)
      box(224, 33, 78, 9, WorkshopStyle.wood, 3)
      for i in 0..<4 {
        let x = CGFloat(232 + i * 19)
        line([CGPoint(x: x, y: 45), CGPoint(x: x, y: 80)], blue.withAlphaComponent(0.3), 5)
        oval(x - 4, 78, 8, 16, gold.withAlphaComponent(0.5))
      }
      box(0, 219, 320, 41, WorkshopStyle.wood, 0)
      for y in stride(from: 226, through: 255, by: 10) {
        line(
          [CGPoint(x: 0, y: y), CGPoint(x: 320, y: y + 2)],
          UIColor(hex: 0xC4A37C).withAlphaComponent(0.4), 1)
      }
      box(15, 177, 36, 42, mint, 5)
      box(20, 171, 26, 7, gold, 2)
      box(263, 191, 38, 28, blue, 4)
      oval(277, 201, 10, 6, gold)
    }
    oval(67, 208, 186, 20, ink.withAlphaComponent(0.12))
    ctx.saveGState()
    ctx.translateBy(x: 160, y: 210)
    ctx.rotate(by: tilt)
    ctx.translateBy(x: -160, y: -210)
    if stage == 0 { ctx.setAlpha(0.72) }
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    switch toy {
    case 0, 8:
      // Tin robot / drummer, with separate feet, arms, face and winding key.
      box(113, 186, 33, 27, blue, 9)
      box(174, 186, 33, 27, blue, 9)
      line([CGPoint(x: 110, y: 143), CGPoint(x: 89, y: 173)], gold, 18)
      line([CGPoint(x: 210, y: 143), CGPoint(x: 232, y: 165)], gold, 18)
      oval(78, 163, 23, 23, red)
      oval(221, 154, 23, 23, red)
      box(112, 128, 96, 69, red, 17)
      box(126, 139, 68, 44, cream, 9)
      oval(148, 150, 24, 24, gold)
      oval(155, 157, 10, 10, ink)
      box(100, 55, 120, 81, red, 23)
      box(112, 66, 96, 58, cream, 17)
      line([CGPoint(x: 160, y: 54), CGPoint(x: 160, y: 39)], gold, 5)
      oval(153, 28, 14, 14, red)
      oval(90, 82, 17, 26, gold)
      oval(213, 82, 17, 26, gold)
      face(89)
      if toy == 8 {
        box(112, 161, 96, 41, blue, 9)
        oval(112, 153, 96, 21, cream)
        for x in stride(from: 124, through: 196, by: 24) {
          line([CGPoint(x: x, y: 176), CGPoint(x: x + 9, y: 193)], gold, 3)
        }
        line([CGPoint(x: 94, y: 169), CGPoint(x: 137, y: 154)], ink, 4)
        line([CGPoint(x: 226, y: 168), CGPoint(x: 185, y: 153)], ink, 4)
      }
    case 1, 6:
      box(77, 132, 170, 62, toy == 1 ? blue : red, 14)
      if toy == 1 {
        box(155, 76, 76, 82, blue, 8)
        box(164, 86, 53, 41, cream, 5)
        box(89, 97, 29, 38, red, 5)
        box(83, 93, 41, 9, gold, 3)
        box(148, 67, 92, 12, red, 4)
        oval(78, 129, 28, 48, gold)
        line([CGPoint(x: 75, y: 192), CGPoint(x: 242, y: 192)], gold, 7)
      } else {
        let p = UIBezierPath()
        p.move(to: CGPoint(x: 104, y: 133))
        p.addLine(to: CGPoint(x: 133, y: 88))
        p.addLine(to: CGPoint(x: 192, y: 88))
        p.addLine(to: CGPoint(x: 223, y: 133))
        p.close()
        red.setFill()
        p.fill()
        box(136, 97, 48, 31, cream, 7)
        box(76, 149, 20, 11, gold, 4)
        box(229, 149, 18, 11, cream, 4)
      }
      wheel(112, 194)
      wheel(209, 194)
      if toy == 1 { wheel(160, 194, 15) }
    case 2, 11:
      box(88, 207, 144, 13, gold, 6)
      if toy == 2 {
        box(98, 184, 124, 24, mint, 6)
        line([CGPoint(x: 160, y: 68), CGPoint(x: 160, y: 186)], gold, 7)
        for x in [120, 160, 200] {
          line([CGPoint(x: x, y: 101), CGPoint(x: x, y: 178)], gold, 3)
          box(CGFloat(x) - 12, 139, 24, 18, cream, 5)
          oval(CGFloat(x) + 3, 129, 12, 19, red)
        }
        let p = UIBezierPath()
        p.move(to: CGPoint(x: 77, y: 108))
        p.addQuadCurve(to: CGPoint(x: 160, y: 49), controlPoint: CGPoint(x: 123, y: 80))
        p.addQuadCurve(to: CGPoint(x: 243, y: 108), controlPoint: CGPoint(x: 197, y: 80))
        p.close()
        mint.setFill()
        p.fill()
        oval(153, 41, 14, 14, gold)
        line([CGPoint(x: 79, y: 109), CGPoint(x: 241, y: 109)], cream, 7)
      } else {
        line([CGPoint(x: 160, y: 125), CGPoint(x: 115, y: 208)], red, 10)
        line([CGPoint(x: 160, y: 125), CGPoint(x: 205, y: 208)], red, 10)
        let ring = UIBezierPath(ovalIn: CGRect(x: 85, y: 44, width: 150, height: 150))
        ring.lineWidth = 7
        gold.setStroke()
        ring.stroke()
        for i in 0..<8 {
          let angle = CGFloat(i) * .pi / 4
          let x = 160 + cos(angle) * 75
          let y = 119 + sin(angle) * 75
          line([CGPoint(x: 160, y: 119), CGPoint(x: x, y: y)], gold, 3)
          box(x - 14, y, 28, 23, i % 2 == 0 ? mint : blue, 6)
        }
        oval(150, 109, 20, 20, red)
      }
    case 3:
      box(70, 116, 180, 35, red, 17)
      let p = UIBezierPath()
      p.move(to: CGPoint(x: 155, y: 58))
      p.addLine(to: CGPoint(x: 189, y: 69))
      p.addLine(to: CGPoint(x: 171, y: 193))
      p.addLine(to: CGPoint(x: 125, y: 193))
      p.close()
      gold.setFill()
      p.fill()
      box(104, 110, 104, 20, red, 8)
      box(173, 117, 38, 16, cream, 8)
      line([CGPoint(x: 65, y: 93), CGPoint(x: 65, y: 170)], blue, 8)
      oval(56, 123, 18, 18, gold)
      box(223, 88, 23, 49, blue, 8)
      wheel(133, 194, 10)
      wheel(183, 194, 10)
    case 4:
      oval(94, 123, 132, 80, gold)
      oval(151, 64, 72, 85, gold)
      oval(193, 99, 46, 20, red)
      eye(195, 93)
      oval(111, 139, 68, 41, cream)
      box(111, 199, 38, 12, red, 5)
      box(178, 199, 38, 12, red, 5)
      line([CGPoint(x: 100, y: 143), CGPoint(x: 78, y: 116)], gold, 17)
    case 5:
      box(76, 92, 168, 117, blue, 19)
      box(91, 77, 48, 21, gold, 6)
      box(176, 79, 46, 19, red, 5)
      box(87, 104, 146, 31, mint, 6)
      oval(117, 115, 86, 86, ink)
      oval(126, 124, 68, 68, gold)
      oval(135, 133, 50, 50, blue)
      oval(144, 140, 16, 16, cream)
      box(91, 145, 16, 35, cream, 3)
      oval(215, 107, 13, 13, cream)
    case 7:
      oval(98, 55, 43, 43, gold)
      oval(179, 55, 43, 43, gold)
      oval(108, 65, 24, 24, red)
      oval(188, 65, 24, 24, red)
      oval(110, 76, 100, 89, gold)
      oval(122, 103, 76, 55, cream)
      face(106)
      oval(117, 151, 86, 58, blue)
      oval(91, 154, 32, 53, gold)
      oval(197, 154, 32, 53, gold)
      oval(117, 192, 34, 25, gold)
      oval(170, 192, 34, 25, gold)
      box(143, 147, 34, 15, red, 5)
    case 9, 10:
      box(100, 132, 116, 57, toy == 9 ? gold : mint, 18)
      box(186, 85, 48, 73, toy == 9 ? gold : mint, 16)
      box(204, 119, 47, 23, cream, 8)
      eye(219, 107)
      line([CGPoint(x: 193, y: 88), CGPoint(x: 186, y: 65)], toy == 9 ? gold : blue, 13)
      line([CGPoint(x: 222, y: 85), CGPoint(x: 227, y: 66)], toy == 9 ? gold : blue, 13)
      for x in [118, 192] { box(CGFloat(x), 174, 15, 34, blue, 5) }
      line([CGPoint(x: 102, y: 143), CGPoint(x: 79, y: 120)], red, 9)
      if toy == 9 {
        let p = UIBezierPath()
        p.move(to: CGPoint(x: 80, y: 204))
        p.addQuadCurve(to: CGPoint(x: 245, y: 204), controlPoint: CGPoint(x: 160, y: 239))
        p.lineWidth = 9
        red.setStroke()
        p.stroke()
        box(139, 128, 44, 15, red, 5)
      } else {
        wheel(120, 205, 13)
        wheel(199, 205, 13)
        box(195, 148, 38, 8, red, 3)
      }
    default: break
    }
    ctx.endTransparencyLayer()
    ctx.restoreGState()
    if stage < 3 {
      // Visible repair progress: two brass fasteners and a repair seam.
      for i in 0..<max(1, 3 - stage) {
        let x = CGFloat(118 + i * 34)
        oval(x, 224, 15, 15, gold)
        line([CGPoint(x: x + 4, y: 231), CGPoint(x: x + 11, y: 231)], ink, 2)
      }
      if stage == 0 {
        line(
          [CGPoint(x: 148, y: 139), CGPoint(x: 158, y: 151), CGPoint(x: 151, y: 163)],
          ink.withAlphaComponent(0.6), 2)
      }
    } else {
      for (x, y) in [(65, 102), (255, 71), (245, 177)] {
        line([CGPoint(x: x - 5, y: y), CGPoint(x: x + 5, y: y)], gold, 2)
        line([CGPoint(x: x, y: y - 5), CGPoint(x: x, y: y + 5)], gold, 2)
      }
    }
  }
}
