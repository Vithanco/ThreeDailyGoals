// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tdgCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .watchOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "tdgCoreWidget",
            targets: ["tdgCoreWidget"]
        ),
        .library(
            name: "tdgCoreMain",
            targets: ["tdgCoreMain"]
        ),
        .library(
            name: "tdgCoreShare",
            targets: ["tdgCoreShare"]
        ),
        .library(
            name: "tdgCoreTest",
            targets: ["tdgCoreTest"]
        ),
        .library(
            name: "tdgCoreMCP",
            targets: ["tdgCoreMCP"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.12.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "tdgCoreWidget",
            dependencies: [],
            path: "Sources/tdgCoreWidget",
            swiftSettings: []
        ),
        .target(
            name: "tdgCoreMain",
            dependencies: ["tdgCoreWidget"],
            path: "Sources/tdgCoreMain"
        ),
        .target(
            name: "tdgCoreShare",
            dependencies: ["tdgCoreMain"],
            path: "Sources/tdgCoreShare"
        ),
        .target(
            name: "tdgCoreTest",
            dependencies: ["tdgCoreShare"],
            path: "Sources/tdgCoreTest"
        ),
        .target(
            name: "tdgCoreMCP",
            dependencies: [
                "tdgCoreMain",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/tdgCoreMCP"
        ),
        .testTarget(
            name: "tdgCoreWidgetTests",
            dependencies: ["tdgCoreWidget"],
            path: "Tests/tdgCoreWidgetTests"
        ),
        .testTarget(
            name: "tdgCoreMainTests",
            dependencies: ["tdgCoreMain"],
            path: "Tests/tdgCoreMainTests"
        ),
        .testTarget(
            name: "tdgCoreShareTests",
            dependencies: ["tdgCoreShare"],
            path: "Tests/tdgCoreShareTests"
        ),
    ]
)
