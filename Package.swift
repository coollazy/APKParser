// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APKParser",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "APKParser",
            targets: [
                "APKParser"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/coollazy/Image.git", .upToNextMinor(from: "1.1.0")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMinor(from: "5.1.2")),
    ],
    targets: [
        .target(
            name: "APKParser",
            dependencies: [
                .product(name: "Image", package: "Image"),
                .product(name: "Yams", package: "Yams"),
                .target(name: "Command"),
            ],
            resources: [
            ]
        ),
        .target(
            name: "Command",
            dependencies: [
            ],
            resources: [
            ]
        ),
    ]
)
