import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Asset packaging only: downsample exported art to its display resolution and
// write an opaque 1024px App Store icon. The untouched source is kept separately.
let args = CommandLine.arguments
let source = URL(fileURLWithPath: args[1])
let destination = URL(fileURLWithPath: args[2])
let icon = args.count > 3 && args[3] == "icon"
let maximum = args.count > 3 && args[3] == "background" ? 1536 : 1024
let data = CGImageSourceCreateWithURL(source as CFURL, nil)!
let options: [CFString: Any] = [
  kCGImageSourceCreateThumbnailFromImageAlways: true,
  kCGImageSourceThumbnailMaxPixelSize: maximum,
  kCGImageSourceCreateThumbnailWithTransform: true,
]
var image = CGImageSourceCreateThumbnailAtIndex(data, 0, options as CFDictionary)!
if icon {
  let context = CGContext(
    data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
    bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
  context.interpolationQuality = .high
  context.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
  image = context.makeImage()!
}
let jpeg = destination.pathExtension == "jpg"
let output = CGImageDestinationCreateWithURL(
  destination as CFURL,
  (jpeg ? UTType.jpeg.identifier : UTType.png.identifier) as CFString, 1, nil)!
CGImageDestinationAddImage(
  output, image, [kCGImageDestinationLossyCompressionQuality: 0.90] as CFDictionary)
precondition(CGImageDestinationFinalize(output), "Unable to export asset")
print(
  "\(destination.lastPathComponent): \(image.width)x\(image.height), alpha=\(image.alphaInfo.rawValue)"
)
