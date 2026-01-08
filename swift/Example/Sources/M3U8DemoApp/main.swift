//
//  main.swift
//  M3U8DemoApp
//
//  M3U8DownloaderKit 命令行演示应用
//  展示如何使用 Swift 包装层进行流媒体下载
//

import Foundation
import M3U8DownloaderKit

/// 主应用程序入口
@main
struct M3U8DemoApp {
    static func main() async {
        let demo = DemoRunner()
        await demo.run()
    }
}

/// 演示运行器
@MainActor
final class DemoRunner {
    
    // MARK: - Test Streams
    
    /// 测试流 URL 列表
    enum TestStream: String, CaseIterable {
        case appleBasic = "Apple Basic HLS"
        case appleAdvanced = "Apple Advanced HEVC"
        case dashClear = "DASH Clear 1080p"
        case dashMultiAudio = "DASH Multi Audio"
        
        var url: String {
            switch self {
            case .appleBasic:
                return "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
            case .appleAdvanced:
                return "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"
            case .dashClear:
                return "https://media.axprod.net/TestVectors/v7-Clear/Manifest_1080p.mpd"
            case .dashMultiAudio:
                return "https://dash.akamaized.net/dash264/TestCases/2c/qualcomm/1/MultiResMPEG2.mpd"
            }
        }
        
        var description: String { rawValue }
    }
    
    // MARK: - Properties
    
    private var downloader: M3U8Downloader?
    
    // MARK: - Main Entry
    
    func run() async {
        printBanner()
        
        // 初始化下载器
        guard await initializeDownloader() else {
            printError("下载器初始化失败，程序退出")
            return
        }
        
        // 显示主菜单
        await mainMenu()
    }
    
    // MARK: - Initialization
    
    private func initializeDownloader() async -> Bool {
        printSection("初始化下载器")
        
        do {
            let config = Configuration(
                maxConcurrency: 8,
                timeoutSeconds: 30,
                retryCount: 3
            )
            
            downloader = try M3U8Downloader(configuration: config)
            
            // 设置日志回调
            downloader?.onLog { level, message in
                self.printLog(level: level, message: message)
            }
            
            // 设置进度回调
            downloader?.onProgress { progress in
                self.printProgress(progress)
            }
            
            printSuccess("下载器初始化成功")
            
            // 显示版本信息
            if let version = M3U8Downloader.getVersion() {
                printInfo("版本: \(version.version) (\(version.platform))")
            }
            
            return true
        } catch {
            printError("初始化失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Menu
    
    private func mainMenu() async {
        while true {
            printSection("主菜单")
            print("""
            
            请选择操作:
            
              1. 解析测试流
              2. 下载测试流
              3. 自定义 URL 解析
              4. 自定义 URL 下载
              5. 查看下载器状态
              6. 运行演示测试
              0. 退出
            
            """)
            
            print("请输入选项: ", terminator: "")
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                continue
            }
            
            switch input {
            case "1":
                await parseTestStream()
            case "2":
                await downloadTestStream()
            case "3":
                await parseCustomURL()
            case "4":
                await downloadCustomURL()
            case "5":
                showDownloaderStatus()
            case "6":
                await runDemoTests()
            case "0", "q", "quit", "exit":
                printInfo("感谢使用 M3U8 Downloader Demo!")
                return
            default:
                printWarning("无效选项，请重新输入")
            }
        }
    }
    
    // MARK: - Actions
    
    /// 解析测试流
    private func parseTestStream() async {
        printSection("选择测试流")
        
        for (index, stream) in TestStream.allCases.enumerated() {
            print("  \(index + 1). \(stream.description)")
        }
        print("  0. 返回")
        
        print("\n请选择: ", terminator: "")
        guard let input = readLine(),
              let choice = Int(input),
              choice > 0,
              choice <= TestStream.allCases.count else {
            return
        }
        
        let stream = TestStream.allCases[choice - 1]
        await parseURL(stream.url)
    }
    
    /// 下载测试流
    private func downloadTestStream() async {
        printSection("选择测试流")
        
        for (index, stream) in TestStream.allCases.enumerated() {
            print("  \(index + 1). \(stream.description)")
        }
        print("  0. 返回")
        
        print("\n请选择: ", terminator: "")
        guard let input = readLine(),
              let choice = Int(input),
              choice > 0,
              choice <= TestStream.allCases.count else {
            return
        }
        
        let stream = TestStream.allCases[choice - 1]
        await downloadURL(stream.url)
    }
    
    /// 自定义 URL 解析
    private func parseCustomURL() async {
        print("\n请输入 URL: ", terminator: "")
        guard let url = readLine()?.trimmingCharacters(in: .whitespaces),
              !url.isEmpty else {
            printWarning("URL 不能为空")
            return
        }
        
        await parseURL(url)
    }
    
    /// 自定义 URL 下载
    private func downloadCustomURL() async {
        print("\n请输入 URL: ", terminator: "")
        guard let url = readLine()?.trimmingCharacters(in: .whitespaces),
              !url.isEmpty else {
            printWarning("URL 不能为空")
            return
        }
        
        await downloadURL(url)
    }
    
    /// 解析 URL
    private func parseURL(_ url: String) async {
        printSection("解析流媒体")
        printInfo("URL: \(url)")
        
        guard let downloader = downloader else {
            printError("下载器未初始化")
            return
        }
        
        do {
            let startTime = Date()
            let result = try await downloader.parse(url: url)
            let elapsed = Date().timeIntervalSince(startTime)
            
            printSuccess("解析成功! 耗时: \(String(format: "%.2f", elapsed))s")
            printInfo("找到 \(result.streams.count) 个流:")
            
            for (index, stream) in result.streams.enumerated() {
                let details = [
                    stream.type.rawValue,
                    stream.resolution,
                    stream.codec,
                    stream.bitrate.map { "\($0 / 1000) kbps" },
                    stream.language,
                    stream.isEncrypted ? "🔒 加密" : nil
                ].compactMap { $0 }.joined(separator: " | ")
                
                print("  \(index + 1). [\(stream.id)] \(details)")
            }
        } catch {
            printError("解析失败: \(error.localizedDescription)")
        }
    }
    
    /// 下载 URL
    private func downloadURL(_ url: String) async {
        printSection("下载流媒体")
        printInfo("URL: \(url)")
        
        guard let downloader = downloader else {
            printError("下载器未初始化")
            return
        }
        
        // 生成输出路径
        let outputDir = FileManager.default.currentDirectoryPath
        let timestamp = Int(Date().timeIntervalSince1970)
        let outputPath = "\(outputDir)/download_\(timestamp).mp4"
        
        printInfo("输出路径: \(outputPath)")
        
        do {
            let options = DownloadOptions(
                autoSelectBestQuality: true
            )
            
            let startTime = Date()
            let result = try await downloader.download(
                url: url,
                to: outputPath,
                options: options
            )
            let elapsed = Date().timeIntervalSince(startTime)
            
            printSuccess("下载完成! 耗时: \(String(format: "%.2f", elapsed))s")
            printInfo("文件: \(result.outputFile ?? "N/A")")
            printInfo("大小: \(result.formattedFileSize)")
            printInfo("时长: \(result.formattedDuration)")
        } catch {
            if case M3U8Error.cancelled = error {
                printWarning("下载已取消")
            } else {
                printError("下载失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 显示下载器状态
    private func showDownloaderStatus() {
        printSection("下载器状态")
        
        if let version = M3U8Downloader.getVersion() {
            printInfo("版本: \(version.version)")
            printInfo("平台: \(version.platform)")
            printInfo("构建时间: \(version.buildDate)")
        } else {
            printWarning("无法获取版本信息")
        }
        
        if downloader != nil {
            printSuccess("下载器状态: 已初始化")
        } else {
            printError("下载器状态: 未初始化")
        }
    }
    
    /// 运行演示测试
    private func runDemoTests() async {
        printSection("运行演示测试")
        
        printInfo("测试 1: 解析 Apple Basic HLS")
        await parseURL(TestStream.appleBasic.url)
        
        print("\n按 Enter 继续...")
        _ = readLine()
        
        printInfo("测试 2: 解析 DASH Clear")
        await parseURL(TestStream.dashClear.url)
        
        printSuccess("演示测试完成!")
    }
    
    // MARK: - Output Helpers
    
    private func printBanner() {
        print("""
        
        ╔════════════════════════════════════════════════════════════╗
        ║                                                            ║
        ║           M3U8 Downloader Kit - Demo Application           ║
        ║                                                            ║
        ║      支持 HLS (M3U8) / DASH (MPD) 流媒体解析和下载         ║
        ║                                                            ║
        ╚════════════════════════════════════════════════════════════╝
        
        """)
    }
    
    private func printSection(_ title: String) {
        print("\n\("─" * 60)")
        print(" 📌 \(title)")
        print("\("─" * 60)")
    }
    
    private func printInfo(_ message: String) {
        print(" ℹ️  \(message)")
    }
    
    private func printSuccess(_ message: String) {
        print(" ✅ \(message)")
    }
    
    private func printWarning(_ message: String) {
        print(" ⚠️  \(message)")
    }
    
    private func printError(_ message: String) {
        print(" ❌ \(message)")
    }
    
    private func printLog(level: LogLevel, message: String) {
        let symbol = level.symbol
        print(" \(symbol) \(message)")
    }
    
    private func printProgress(_ progress: DownloadProgress) {
        let bar = createProgressBar(percentage: progress.percentage)
        print("\r \(bar) \(String(format: "%.1f%%", progress.percentage)) | \(progress.formattedSpeed)", terminator: "")
        fflush(stdout)
        
        if progress.percentage >= 100 {
            print() // 换行
        }
    }
    
    private func createProgressBar(percentage: Double, width: Int = 30) -> String {
        let filled = Int(percentage / 100.0 * Double(width))
        let empty = width - filled
        return "[" + String(repeating: "█", count: filled) + String(repeating: "░", count: empty) + "]"
    }
}

// MARK: - String Extension

extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}
