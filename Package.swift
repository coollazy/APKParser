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
        .library(
            name: "APKSigner",
            targets: [
                "APKSigner"
            ]
        ),
        .library(
            name: "Command",
            targets: [
                "Command"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/coollazy/Image.git", from: "1.2.1"),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMinor(from: "5.1.2")),
        .package(url: "https://github.com/coollazy/APKSignKey.git", from: "1.1.0"),
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
            name: "APKSigner",
            dependencies: [
                .product(name: "APKSignKey", package: "APKSignKey"),
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
        .testTarget(
            name: "APKParserTests",
            dependencies: ["APKParser", "APKSigner", "Command"],
            resources: [.process("Resources")]
        ),
    ]
)
