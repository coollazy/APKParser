// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Example",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "App",
            targets: ["App"]
        ),
    ],
    dependencies: [
        .package(path: "../"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "APKParser", package: "APKParser"),
            ]
        ),
    ]
)
