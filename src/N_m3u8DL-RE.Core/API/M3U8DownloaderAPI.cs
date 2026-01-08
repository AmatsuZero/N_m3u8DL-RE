using N_m3u8DL_RE.Core.Abstraction;
using N_m3u8DL_RE.Core.VideoProcessor;
using N_m3u8DL_RE.Core.Downloader;
using N_m3u8DL_RE.Core.Config;
using N_m3u8DL_RE.Parser;
using N_m3u8DL_RE.Parser.Config;
using N_m3u8DL_RE.Common.Entity;
using N_m3u8DL_RE.Common.Enum;
using System.Diagnostics;

namespace N_m3u8DL_RE.Core.API;

/// <summary>
/// N_m3u8DL-RE iOS核心库 - 主API接口
/// </summary>
public class M3U8DownloaderAPI
{
    private readonly ILogger _logger;
    private readonly VideoProcessorFactory _processorFactory;
    private readonly VideoProcessorManager _processorManager;
    private DownloaderConfiguration? _config;
    private bool _initialized;

    /// <summary>
    /// 构造函数
    /// </summary>
    /// <param name="logger">日志记录器（可选）</param>
    public M3U8DownloaderAPI(ILogger? logger = null)
    {
        _logger = logger ?? NullLogger.Instance;
        _processorFactory = new VideoProcessorFactory(_logger);
        _processorManager = new VideoProcessorManager(_processorFactory, _logger);
        _initialized = false;
    }

    /// <summary>
    /// 初始化下载器
    /// </summary>
    /// <param name="config">配置选项</param>
    public async Task InitializeAsync(DownloaderConfiguration? config = null)
    {
        if (_initialized)
        {
            _logger.Warn("Downloader already initialized");
            return;
        }

        _logger.Info("Initializing M3U8 Downloader...");

        // 保存配置
        _config = config ?? new DownloaderConfiguration();

        // 注册基础视频处理器（始终可用）
        _processorFactory.RegisterProcessor(new BasicVideoProcessor(_logger));

        // TODO: 根据配置注册其他处理器（iOS原生、FFmpeg等）

        // 选择最佳处理器
        await _processorFactory.SelectBestProcessorAsync();

        _initialized = true;
        _logger.Info("M3U8 Downloader initialized successfully");
    }

    /// <summary>
    /// 下载M3U8流
    /// </summary>
    /// <param name="request">下载请求</param>
    /// <param name="progressCallback">进度回调（可选）</param>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>下载结果</returns>
    public async Task<DownloadResult> DownloadAsync(
        DownloadRequest request,
        IDownloadProgressCallback? progressCallback = null,
        CancellationToken cancellationToken = default)
    {
        EnsureInitialized();

        _logger.Info($"Starting download: {request.Url}");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            // 1. 解析M3U8
            _logger.Info("Step 1: Parsing M3U8...");
            var parseResult = await ParseAsync(request.Url, cancellationToken);
            if (!parseResult.Success)
            {
                return new DownloadResult
                {
                    Success = false,
                    ErrorMessage = $"Parse failed: {parseResult.ErrorMessage}"
                };
            }

            // 2. 选择流（自动选择最佳质量或第一个）
            var selectedStream = request.AutoSelectBestQuality
                ? parseResult.Streams.OrderByDescending(s => s.Bitrate).FirstOrDefault()
                : parseResult.Streams.FirstOrDefault();

            if (selectedStream == null)
            {
                return new DownloadResult
                {
                    Success = false,
                    ErrorMessage = "No streams found"
                };
            }

            _logger.Info($"Selected stream: {selectedStream.Resolution} @ {selectedStream.Bitrate} bps");

            // 3. 创建临时目录
            var tempDir = _config?.TempDirectory ?? Path.Combine(Path.GetTempPath(), $"m3u8dl_{Guid.NewGuid():N}");
            Directory.CreateDirectory(tempDir);

            try
            {
                // 4. 下载分片（简化版本 - 实际需要更复杂的逻辑）
                _logger.Info("Step 2: Downloading segments...");
                progressCallback?.OnProgressUpdate(new DownloadProgress
                {
                    TaskId = 1,
                    Description = "Preparing download...",
                    CurrentValue = 0,
                    MaxValue = 100,
                    Speed = 0
                });

                // TODO: 实现实际的分片下载逻辑
                // 这里需要：
                // - 获取StreamSpec
                // - 使用SimpleDownloader下载每个分片
                // - 处理加密
                // - 报告进度

                // 5. 合并文件
                _logger.Info("Step 3: Merging segments...");
                progressCallback?.OnProgressUpdate(new DownloadProgress
                {
                    TaskId = 1,
                    Description = "Merging...",
                    CurrentValue = 100,
                    MaxValue = 100,
                    Speed = 0
                });

                // TODO: 使用视频处理器合并文件

                stopwatch.Stop();

                // 6. 清理临时文件
                if (_config?.AutoCleanup ?? true)
                {
                    try
                    {
                        Directory.Delete(tempDir, true);
                    }
                    catch (Exception ex)
                    {
                        _logger.Warn($"Failed to cleanup temp directory: {ex.Message}");
                    }
                }

                var result = new DownloadResult
                {
                    Success = true,
                    OutputFile = request.OutputPath,
                    Duration = stopwatch.Elapsed.TotalSeconds
                };

                progressCallback?.OnDownloadCompleted(1, true);
                _logger.Info($"Download completed in {result.Duration:F2} seconds");

                return result;
            }
            catch
            {
                // 清理临时文件
                try
                {
                    if (Directory.Exists(tempDir))
                    {
                        Directory.Delete(tempDir, true);
                    }
                }
                catch { }
                throw;
            }
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.Error($"Download failed: {ex.Message}");
            progressCallback?.OnDownloadFailed(1, ex.Message);
            
            return new DownloadResult
            {
                Success = false,
                ErrorMessage = ex.Message,
                Duration = stopwatch.Elapsed.TotalSeconds
            };
        }
    }

    /// <summary>
    /// 解析M3U8文件
    /// </summary>
    /// <param name="url">M3U8 URL</param>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>解析结果</returns>
    public async Task<ParseResult> ParseAsync(string url, CancellationToken cancellationToken = default)
    {
        EnsureInitialized();

        _logger.Info($"Parsing M3U8: {url}");

        try
        {
            // 创建解析器配置
            var parserConfig = new ParserConfig
            {
                Url = url,
                Headers = new Dictionary<string, string>()
            };

            // 创建流提取器
            var extractor = new StreamExtractor(parserConfig);

            // 加载M3U8内容
            await extractor.LoadSourceFromUrlAsync(url);

            // 解析流信息
            var streams = await extractor.ExtractStreamsAsync();

            // 转换为API结果
            var result = new ParseResult
            {
                Success = true,
                Streams = streams.Select(ConvertToStreamInfo).ToList()
            };

            _logger.Info($"Parse completed: found {result.Streams.Count} streams");
            return result;
        }
        catch (Exception ex)
        {
            _logger.Error($"Parse failed: {ex.Message}");
            return new ParseResult
            {
                Success = false,
                ErrorMessage = ex.Message
            };
        }
    }

    /// <summary>
    /// 转换StreamSpec到StreamInfo
    /// </summary>
    private StreamInfo ConvertToStreamInfo(StreamSpec spec)
    {
        return new StreamInfo
        {
            Id = spec.GroupId,
            Type = spec.MediaType?.ToString() ?? "video",
            Codec = spec.Codecs,
            Bitrate = spec.Bandwidth,
            Resolution = spec.Resolution,
            Language = spec.Language,
            IsEncrypted = spec.Playlist?.MediaParts.Any(p => p.MediaSegments.Any(s => s.EncryptInfo.Method != EncryptMethod.NONE)) ?? false
        };
    }

    /// <summary>
    /// 获取视频处理器管理器（高级用法）
    /// </summary>
    /// <returns>视频处理器管理器</returns>
    public VideoProcessorManager GetVideoProcessorManager()
    {
        EnsureInitialized();
        return _processorManager;
    }

    /// <summary>
    /// 获取视频处理器工厂（高级用法）
    /// </summary>
    /// <returns>视频处理器工厂</returns>
    public VideoProcessorFactory GetVideoProcessorFactory()
    {
        EnsureInitialized();
        return _processorFactory;
    }

    /// <summary>
    /// 检查功能是否可用
    /// </summary>
    /// <param name="feature">功能名称</param>
    /// <returns>是否可用</returns>
    public async Task<bool> IsFeatureAvailableAsync(string feature)
    {
        EnsureInitialized();
        return await _processorManager.IsFeatureAvailableAsync(feature);
    }

    private void EnsureInitialized()
    {
        if (!_initialized)
        {
            throw new InvalidOperationException("Downloader not initialized. Call InitializeAsync() first.");
        }
    }
}

/// <summary>
/// 下载器配置
/// </summary>
public class DownloaderConfiguration
{
    /// <summary>
    /// 最大并发下载数
    /// </summary>
    public int MaxConcurrency { get; set; } = 8;

    /// <summary>
    /// 下载超时时间（秒）
    /// </summary>
    public int TimeoutSeconds { get; set; } = 30;

    /// <summary>
    /// 重试次数
    /// </summary>
    public int RetryCount { get; set; } = 3;

    /// <summary>
    /// 临时文件目录
    /// </summary>
    public string? TempDirectory { get; set; }

    /// <summary>
    /// 是否自动清理临时文件
    /// </summary>
    public bool AutoCleanup { get; set; } = true;

    /// <summary>
    /// 自定义HTTP头
    /// </summary>
    public Dictionary<string, string> CustomHeaders { get; set; } = new();
}

/// <summary>
/// 下载请求
/// </summary>
public class DownloadRequest
{
    /// <summary>
    /// M3U8 URL
    /// </summary>
    public required string Url { get; set; }

    /// <summary>
    /// 输出文件路径
    /// </summary>
    public required string OutputPath { get; set; }

    /// <summary>
    /// 解密密钥（可选）
    /// </summary>
    public List<string>? DecryptionKeys { get; set; }

    /// <summary>
    /// 自定义HTTP头（可选）
    /// </summary>
    public Dictionary<string, string>? CustomHeaders { get; set; }

    /// <summary>
    /// 是否自动选择最佳质量
    /// </summary>
    public bool AutoSelectBestQuality { get; set; } = true;
}

/// <summary>
/// 下载结果
/// </summary>
public class DownloadResult
{
    /// <summary>
    /// 是否成功
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// 输出文件路径
    /// </summary>
    public string? OutputFile { get; set; }

    /// <summary>
    /// 文件大小（字节）
    /// </summary>
    public long? FileSize { get; set; }

    /// <summary>
    /// 下载时长（秒）
    /// </summary>
    public double? Duration { get; set; }

    /// <summary>
    /// 错误消息
    /// </summary>
    public string? ErrorMessage { get; set; }

    /// <summary>
    /// 详细信息
    /// </summary>
    public Dictionary<string, string> Details { get; set; } = new();
}

/// <summary>
/// 解析结果
/// </summary>
public class ParseResult
{
    /// <summary>
    /// 是否成功
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// 错误消息
    /// </summary>
    public string? ErrorMessage { get; set; }

    /// <summary>
    /// 可用的流列表
    /// </summary>
    public List<StreamInfo> Streams { get; set; } = new();
}

/// <summary>
/// 流信息
/// </summary>
public class StreamInfo
{
    /// <summary>
    /// 流ID
    /// </summary>
    public string? Id { get; set; }

    /// <summary>
    /// 流类型（video/audio/subtitle）
    /// </summary>
    public string? Type { get; set; }

    /// <summary>
    /// 编码格式
    /// </summary>
    public string? Codec { get; set; }

    /// <summary>
    /// 比特率
    /// </summary>
    public long? Bitrate { get; set; }

    /// <summary>
    /// 分辨率（视频）
    /// </summary>
    public string? Resolution { get; set; }

    /// <summary>
    /// 语言
    /// </summary>
    public string? Language { get; set; }

    /// <summary>
    /// 是否加密
    /// </summary>
    public bool IsEncrypted { get; set; }
}
