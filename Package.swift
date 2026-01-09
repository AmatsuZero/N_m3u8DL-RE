// swift-tools-version:5.9
//
//  Package.swift
//  M3U8DownloaderKit
//
//  M3U8/HLS/DASH 流媒体下载库的 Objective-C 封装层
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
        // 主要库产品 - Objective-C 实现
        .library(
            name: "M3U8DownloaderKit",
            targets: ["M3U8DownloaderKit"]
        ),
    ],
    dependencies: [
        // 外部依赖（如果需要）
    ],
    targets: [
        // M3U8Core - .NET NativeAOT 编译的底层 C 库
        // 使用 binaryTarget 引入本地 XCFramework
        .binaryTarget(
            name: "M3U8Core",
            path: "build/xcframework/M3U8Core.xcframework"
        ),
        
        // Objective-C 封装层
        // 直接调用 M3U8Core.xcframework 中的 C API
        .target(
            name: "M3U8DownloaderKit",
            dependencies: ["M3U8Core"],
            path: "Sources/M3U8DownloaderKitObjC",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                // 系统库
                .linkedLibrary("z"),
                .linkedLibrary("c++")
            ]
        ),
        
        // 单元测试
        // 注意：由于依赖 XCFramework，测试需要在真实设备或模拟器上运行
        .testTarget(
            name: "M3U8DownloaderKitTests",
            dependencies: ["M3U8DownloaderKit"],
            path: "Tests/M3U8DownloaderKitTests",
            resources: [
                .copy("Resources")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
