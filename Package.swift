// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sMock",
    products: [
        .library(
            name: "sMock",
            targets: ["sMock"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "sMock",
            dependencies: []),
    ]
)
