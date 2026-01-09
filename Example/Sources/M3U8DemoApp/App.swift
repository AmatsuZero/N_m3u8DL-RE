//
//  App.swift
//  M3U8DemoApp
//
//  M3U8DownloaderKit 命令行演示应用
//  展示如何使用 Objective-C 封装层进行流媒体下载
//

import Foundation

// 导入 Objective-C 封装层
// SPM 和 CocoaPods 环境统一使用 M3U8DownloaderKit
#if canImport(M3U8DownloaderKit)
import M3U8DownloaderKit
#endif

/// 主应用程序入口
@main
struct M3U8DemoApp {
    static func main() {
        let demo = DemoRunner()
        demo.run()
    }
}

/// 演示运行器
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
    
    #if canImport(M3U8DownloaderKit)
    private var downloader: M3U8Downloader?
    #endif
    
    // MARK: - Main Entry
    
    func run() {
        printBanner()
        
        #if canImport(M3U8DownloaderKit)
        // 初始化下载器
        guard initializeDownloader() else {
            printError("下载器初始化失败，程序退出")
            return
        }
        
        // 显示主菜单
        mainMenu()
        #else
        printError("M3U8DownloaderKit 模块未找到")
        printInfo("请确保已正确配置 XCFramework 和 Pod 依赖")
        #endif
    }
    
    // MARK: - Initialization
    
    #if canImport(M3U8DownloaderKit)
    private func initializeDownloader() -> Bool {
        printSection("初始化下载器")
        
        // 创建配置
        let config = M3U8Configuration.default()
        config.threadCount = 8
        config.connectionTimeout = 30
        config.maxRetryCount = 3
        
        // 初始化下载器
        do {
            downloader = try M3U8Downloader(configuration: config)
        } catch {
            printError("下载器初始化失败: \(error.localizedDescription)")
            return false
        }
        
        guard let downloader = downloader else {
            printError("下载器初始化失败")
            return false
        }
        
        // 设置日志回调
        downloader.setLogHandler { [weak self] level, message in
            self?.printLog(level: level, message: message)
        }
        
        printSuccess("下载器初始化成功")
        
        return true
    }
    #endif
    
    // MARK: - Menu
    
    #if canImport(M3U8DownloaderKit)
    private func mainMenu() {
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
                parseTestStream()
            case "2":
                downloadTestStream()
            case "3":
                parseCustomURL()
            case "4":
                downloadCustomURL()
            case "5":
                showDownloaderStatus()
            case "6":
                runDemoTests()
            case "0", "q", "quit", "exit":
                cleanup()
                printInfo("感谢使用 M3U8 Downloader Demo!")
                return
            default:
                printWarning("无效选项，请重新输入")
            }
        }
    }
    
    // MARK: - Actions
    
    /// 解析测试流
    private func parseTestStream() {
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
        parseURL(stream.url)
    }
    
    /// 下载测试流
    private func downloadTestStream() {
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
        downloadURL(stream.url)
    }
    
    /// 自定义 URL 解析
    private func parseCustomURL() {
        print("\n请输入 URL: ", terminator: "")
        guard let url = readLine()?.trimmingCharacters(in: .whitespaces),
              !url.isEmpty else {
            printWarning("URL 不能为空")
            return
        }
        
        parseURL(url)
    }
    
    /// 自定义 URL 下载
    private func downloadCustomURL() {
        print("\n请输入 URL: ", terminator: "")
        guard let url = readLine()?.trimmingCharacters(in: .whitespaces),
              !url.isEmpty else {
            printWarning("URL 不能为空")
            return
        }
        
        downloadURL(url)
    }
    
    /// 解析 URL
    private func parseURL(_ url: String) {
        printSection("解析流媒体")
        printInfo("URL: \(url)")
        
        guard let downloader = downloader else {
            printError("下载器未初始化")
            return
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        let startTime = Date()
        
        downloader.parseURL(url) { [weak self] result, error in
            defer { semaphore.signal() }
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            if let error = error {
                self?.printError("解析失败: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, result.success else {
                self?.printError("解析失败: \(result?.errorMessage ?? "未知错误")")
                return
            }
            
            self?.printSuccess("解析成功! 耗时: \(String(format: "%.2f", elapsed))s")
            self?.printInfo("找到 \(result.streams.count) 个流:")
            
            if result.isLive {
                self?.printInfo("类型: 直播流")
            } else if result.duration > 0 {
                self?.printInfo("时长: \(String(format: "%.1f", result.duration))s")
            }
            
            for (index, stream) in result.streams.enumerated() {
                var details: [String] = []
                
                // 流类型
                switch stream.type {
                case .video:
                    details.append("视频")
                case .audio:
                    details.append("音频")
                case .subtitle:
                    details.append("字幕")
                @unknown default:
                    details.append("其他")
                }
                
                // 分辨率
                if let resolution = stream.resolution, !resolution.isEmpty {
                    details.append(resolution)
                }
                
                // 编解码器
                if let codecs = stream.codecs, !codecs.isEmpty {
                    details.append(codecs)
                }
                
                // 带宽
                if stream.bandwidth > 0 {
                    details.append("\(stream.bandwidth / 1000) kbps")
                }
                
                // 语言
                if let language = stream.language, !language.isEmpty {
                    details.append(language)
                }
                
                // 名称
                if let name = stream.name, !name.isEmpty {
                    details.append(name)
                }
                
                let detailsStr = details.joined(separator: " | ")
                print("  \(index + 1). \(detailsStr)")
            }
        }
        
        semaphore.wait()
    }
    
    /// 下载 URL
    private func downloadURL(_ url: String) {
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
        
        let semaphore = DispatchSemaphore(value: 0)
        let startTime = Date()
        
        let options = M3U8DownloadOptions.default()
        options.autoSelectBestQuality = true
        
        downloader.downloadURL(
            url,
            toPath: outputPath,
            options: options,
            progress: { [weak self] progress in
                self?.printProgress(progress)
            },
            completion: { [weak self] result, error in
                defer { semaphore.signal() }
                
                let elapsed = Date().timeIntervalSince(startTime)
                
                if let error = error as NSError? {
                    // M3U8ErrorCodeCancelled = 3001
                    if error.domain == M3U8ErrorDomain && error.code == 3001 {
                        self?.printWarning("下载已取消")
                    } else {
                        self?.printError("下载失败: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let result = result, result.success else {
                    self?.printError("下载失败: \(result?.errorMessage ?? "未知错误")")
                    return
                }
                
                print() // 换行（进度条后）
                self?.printSuccess("下载完成! 耗时: \(String(format: "%.2f", elapsed))s")
                
                if let outputFile = result.outputFile {
                    self?.printInfo("文件: \(outputFile)")
                }
                
                if result.fileSize > 0 {
                    let formattedSize = self?.formatFileSize(result.fileSize) ?? "\(result.fileSize) bytes"
                    self?.printInfo("大小: \(formattedSize)")
                }
                
                if result.duration > 0 {
                    let formattedDuration = self?.formatDuration(result.duration) ?? "\(result.duration)s"
                    self?.printInfo("时长: \(formattedDuration)")
                }
            }
        )
        
        semaphore.wait()
    }
    
    /// 显示下载器状态
    private func showDownloaderStatus() {
        printSection("下载器状态")
        
        if let downloader = downloader {
            if downloader.isDisposed {
                printError("下载器状态: 已释放")
            } else {
                printSuccess("下载器状态: 已初始化")
                
                // 显示当前状态
                let status = downloader.currentStatus
                let statusStr: String
                switch status {
                case .idle:
                    statusStr = "空闲"
                case .parsing:
                    statusStr = "解析中"
                case .downloading:
                    statusStr = "下载中"
                case .merging:
                    statusStr = "合并中"
                case .completed:
                    statusStr = "已完成"
                case .failed:
                    statusStr = "失败"
                case .cancelled:
                    statusStr = "已取消"
                @unknown default:
                    statusStr = "未知"
                }
                printInfo("当前状态: \(statusStr)")
            }
        } else {
            printError("下载器状态: 未初始化")
        }
        
        // 显示版本信息
        if let versionInfo = M3U8Downloader.versionInfo() {
            printInfo("库版本: \(versionInfo.version)")
            if !versionInfo.supportedFeatures.isEmpty {
                printInfo("支持功能: \(versionInfo.supportedFeatures.joined(separator: ", "))")
            }
        }
    }
    
    /// 运行演示测试
    private func runDemoTests() {
        printSection("运行演示测试")
        
        printInfo("测试 1: 解析 Apple Basic HLS")
        parseURL(TestStream.appleBasic.url)
        
        print("\n按 Enter 继续...")
        _ = readLine()
        
        printInfo("测试 2: 解析 DASH Clear")
        parseURL(TestStream.dashClear.url)
        
        printSuccess("演示测试完成!")
    }
    
    /// 清理资源
    private func cleanup() {
        downloader?.dispose()
        downloader = nil
    }
    #endif
    
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
    
    #if canImport(M3U8DownloaderKit)
    private func printLog(level: M3U8LogLevel, message: String) {
        let symbol: String
        switch level {
        case .debug:
            symbol = "🔍"
        case .info:
            symbol = "ℹ️"
        case .warn:
            symbol = "⚠️"
        case .error:
            symbol = "❌"
        @unknown default:
            symbol = "📝"
        }
        print(" \(symbol) \(message)")
    }
    
    private func printProgress(_ progress: M3U8DownloadProgress) {
        let percentage = Double(progress.percentage)
        let bar = createProgressBar(percentage: percentage)
        let speed = formatSpeed(Double(progress.speed))
        
        var statusStr = ""
        if let task = progress.currentTask, !task.isEmpty {
            statusStr = " | \(task)"
        }
        
        print("\r \(bar) \(String(format: "%.1f%%", percentage)) | \(speed)\(statusStr)", terminator: "")
        fflush(stdout)
    }
    #endif
    
    private func createProgressBar(percentage: Double, width: Int = 30) -> String {
        let filled = Int(percentage / 100.0 * Double(width))
        let empty = width - filled
        return "[" + String(repeating: "█", count: max(0, filled)) + String(repeating: "░", count: max(0, empty)) + "]"
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = Double(bytes)
        var unitIndex = 0
        
        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", size, units[unitIndex])
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1024 * 1024 {
            return String(format: "%.2f MB/s", bytesPerSecond / (1024 * 1024))
        } else if bytesPerSecond >= 1024 {
            return String(format: "%.2f KB/s", bytesPerSecond / 1024)
        } else {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
    }
}

// MARK: - String Extension

extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}
