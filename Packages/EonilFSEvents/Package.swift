// swift-tools-version:5.1
// Local vendored copy of EonilFSEvents 0.1.7 (github.com/eonil/FSEvents, upstream
// repository deleted). Only the library product is kept; the upstream demo/CLI
// targets are omitted.

import PackageDescription

let package = Package(
    name: "EonilFSEvents",
    platforms: [
        .macOS(.v10_10),
    ],
    products: [
        .library(name: "EonilFSEvents", targets: ["EonilFSEvents"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "EonilFSEvents", dependencies: []),
    ]
)
