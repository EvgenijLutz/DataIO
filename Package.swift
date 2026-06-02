// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataIO",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .visionOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(
            name: "DataIO",
            targets: ["DataIO"]
        ),
    ],
    targets: [
        .target(
            name: "DataIO"
        ),
        .testTarget(
            name: "DataIOTests",
            dependencies: ["DataIO"]
        ),
    ]
)
