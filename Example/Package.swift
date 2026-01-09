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
        // 本地依赖 M3U8DownloaderKit (根目录的 Package.swift)
        // 注意：SPM 使用目录名 'N_m3u8DL-RE' 作为本地包标识符
        .package(path: "../"),
    ],
    targets: [
        // 注意：不需要单独声明 M3U8Core binaryTarget
        // 因为 M3U8DownloaderKit 内部已经依赖了 M3U8Core
        // SPM 会自动处理传递性依赖的链接
        
        .executableTarget(
            name: "M3U8DemoApp",
            dependencies: [
                // 使用 Objective-C 封装层
                // package 标识符是 'N_m3u8DL-RE'（目录名），product name 是 'M3U8DownloaderKit'
                .product(name: "M3U8DownloaderKit", package: "N_m3u8DL-RE"),
            ],
            path: "Sources/M3U8DemoApp"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
