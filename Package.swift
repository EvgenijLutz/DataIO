// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataIO",
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
