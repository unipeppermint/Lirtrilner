import UIKit

@MainActor enum LirtrilnerRepairAppearance {
  static func token(symbol: String, top: UInt32, bottom: UInt32, size: CGFloat) -> UIImage {
    let canvas = CGSize(width: size, height: size + 4)
    return UIGraphicsImageRenderer(size: canvas).image { renderer in
      let context = renderer.cgContext
      let circle = CGRect(x: 3, y: 2, width: size - 6, height: size - 6)
      context.saveGState()
      context.setShadow(offset: CGSize(width: 0, height: 2), blur: 2,
                        color: UIColor(hex: 0x613C24).withAlphaComponent(0.25).cgColor)
      UIColor(hex: bottom).setFill()
      UIBezierPath(ovalIn: circle).fill()
      context.restoreGState()
      context.saveGState()
      context.addEllipse(in: circle)
      context.clip()
      let colors = [UIColor(hex: top).cgColor, UIColor(hex: bottom).cgColor] as CFArray
      if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                   locations: [0, 1]) {
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: circle.minY),
                                   end: CGPoint(x: 0, y: circle.maxY), options: [])
      }
      context.restoreGState()
      UIColor(hex: 0xFFF8E8).setStroke()
      let rim = UIBezierPath(ovalIn: circle.insetBy(dx: 1.5, dy: 1.5))
      rim.lineWidth = 1.5
      rim.stroke()
      UIColor.white.withAlphaComponent(0.30).setStroke()
      let inset = UIBezierPath(ovalIn: circle.insetBy(dx: 4, dy: 4))
      inset.lineWidth = 0.7
      inset.stroke()
      let configuration = UIImage.SymbolConfiguration(pointSize: size * 0.38, weight: .bold)
      let icon = UIImage(systemName: symbol, withConfiguration: configuration)?
        .withTintColor(.white, renderingMode: .alwaysOriginal)
      if let icon {
        icon.draw(in: CGRect(x: (size - icon.size.width) / 2,
                             y: circle.midY - icon.size.height / 2,
                             width: icon.size.width, height: icon.size.height))
      }
    }
  }

  static func button(_ title: String, symbol: String, top: UInt32, bottom: UInt32,
                     compact: Bool, action: @escaping () -> Void) -> UIButton {
    var config = UIButton.Configuration.plain()
    config.title = title
    config.image = token(symbol: symbol, top: top, bottom: bottom, size: compact ? 54 : 62)
    config.imagePlacement = .top
    config.imagePadding = 3
    config.baseForegroundColor = WorkshopStyle.ink
    config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 2, bottom: 4, trailing: 2)
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
      var value = attributes
      value.font = WorkshopStyle.font(13, weight: .semibold)
      return value
    }
    let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
    button.titleLabel?.numberOfLines = 0
    return button
  }

  static func part(_ kind: PartKind, level: Int, size: CGFloat) -> LirtrilnerPartView {
    let view = LirtrilnerPartView()
    view.part = Part(id: -1, kind: kind, level: level)
    view.widthAnchor.constraint(equalToConstant: size).isActive = true
    view.heightAnchor.constraint(equalToConstant: size).isActive = true
    return view
  }
}
