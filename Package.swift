// swift-tools-version:5.9
//
//  Package.swift
//  M3U8DownloaderKit
//
//  M3U8/HLS/DASH 流媒体下载库的 Swift 包装层
//
//  支持平台:
//  - iOS 15.0+
//  - macOS 12.0+
//
//  集成方式:
//  - Swift Package Manager (推荐)
//  - CocoaPods
//

import PackageDescription

let package = Package(
    name: "M3U8DownloaderKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        // 主要库产品
        .library(
            name: "M3U8DownloaderKit",
            targets: ["M3U8DownloaderKit"]
        ),
        // 仅模型库（用于测试，不依赖 C 库）
        .library(
            name: "M3U8DownloaderKitModels",
            targets: ["M3U8DownloaderKitModels"]
        ),
    ],
    dependencies: [
        // 外部依赖（如果需要）
    ],
    targets: [
        // C 桥接模块
        .target(
            name: "M3U8DownloaderKit_C",
            dependencies: [],
            path: "Sources/M3U8DownloaderKit_C",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                // 链接 XCFramework（iOS 和 macOS）
                .linkedFramework("M3U8DownloaderKit", .when(platforms: [.iOS, .macOS])),
                .linkedFramework("Foundation"),
                // 系统库
                .linkedLibrary("z"),
                .linkedLibrary("c++")
            ]
        ),
        
        // 纯 Swift 模型层（不依赖 C 库）
        .target(
            name: "M3U8DownloaderKitModels",
            dependencies: [],
            path: "Sources/M3U8DownloaderKitModels",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        
        // Swift 包装层（完整版，依赖 C 库）
        .target(
            name: "M3U8DownloaderKit",
            dependencies: ["M3U8DownloaderKit_C", "M3U8DownloaderKitModels"],
            path: "Sources/M3U8DownloaderKit",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        
        // 单元测试（仅测试纯 Swift 模型，不依赖 C 库）
        .testTarget(
            name: "M3U8DownloaderKitTests",
            dependencies: ["M3U8DownloaderKitModels"],
            path: "Tests/M3U8DownloaderKitTests",
            resources: [
                .copy("Resources")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
