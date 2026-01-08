// swift-tools-version:5.9
//
//  Package.swift
//  M3U8DemoApp
//
//  M3U8DownloaderKit 演示应用
//  使用 Swift Package Manager 管理
//

import PackageDescription

let package = Package(
    name: "M3U8DemoApp",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        // macOS 命令行演示应用
        .executable(
            name: "M3U8DemoApp",
            targets: ["M3U8DemoApp"]
        ),
    ],
    dependencies: [
        // 本地依赖 M3U8DownloaderKit
        // 注意: 包标识符使用目录名 "swift"
        .package(path: "../"),
    ],
    targets: [
        .executableTarget(
            name: "M3U8DemoApp",
            dependencies: [
                .product(name: "M3U8DownloaderKit", package: "swift"),
            ],
            path: "Sources/M3U8DemoApp",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
