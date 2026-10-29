// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "LirtrilnerCore",
  platforms: [.macOS(.v13)],
  products: [.library(name: "LirtrilnerCore", targets: ["LirtrilnerCore"])],
  targets: [
    .target(name: "LirtrilnerCore", path: "Lirtrilner/Core"),
    .testTarget(
      name: "LirtrilnerCoreTests", dependencies: ["LirtrilnerCore"],
      path: "Tests/LirtrilnerCoreTests"),
  ]
)
