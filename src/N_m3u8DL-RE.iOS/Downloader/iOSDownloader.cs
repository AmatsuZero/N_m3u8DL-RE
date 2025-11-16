using N_m3u8DL_RE.iOS.Config;
using N_m3u8DL_RE.iOS.Entity;
using N_m3u8DL_RE.Parser;
using N_m3u8DL_RE.Common.Entity;
using N_m3u8DL_RE.Parser.Config;

namespace N_m3u8DL_RE.iOS.Downloader;

/// <summary>
/// iOS 下载器实现
/// </summary>
public class iOSDownloader : IiOSDownloader
{
    private CancellationTokenSource? _cancellationTokenSource;
    private DownloadProgress _currentProgress = new();
    private readonly HttpClient _httpClient;

    public iOSDownloader()
    {
        _httpClient = new HttpClient();
    }

    /// <summary>
    /// 开始下载
    /// </summary>
    public async Task<DownloadResult> DownloadAsync(
        iOSDownloaderConfig config, 
        IProgress<DownloadProgress>? progress = null, 
        CancellationToken cancellationToken = default)
    {
        var startTime = DateTime.Now;
        
        try
        {
            // 验证配置
            if (!config.IsValid())
            {
                return new DownloadResult
                {
                    Success = false,
                    ErrorCode = -1,
                    ErrorMessage = "Invalid configuration"
                };
            }

            // 创建取消令牌
            _cancellationTokenSource = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);

            // 更新状态：初始化中
            UpdateProgress(DownloadStatus.Initializing, 0, 0, 0, progress);

            // 配置 HttpClient
            ConfigureHttpClient(config);

            // 解析流媒体
            var parserConfig = CreateParserConfig(config);
            var streamExtractor = new StreamExtractor(parserConfig);
            
            UpdateProgress(DownloadStatus.Initializing, 5, 0, 0, progress);

            // 加载并解析流
            await streamExtractor.LoadSourceFromUrlAsync(config.Url);
            var streams = await streamExtractor.ExtractStreamsAsync();

            if (streams == null || streams.Count == 0)
            {
                return new DownloadResult
                {
                    Success = false,
                    ErrorCode = -2,
                    ErrorMessage = "No streams found"
                };
            }

            UpdateProgress(DownloadStatus.Downloading, 10, 0, 0, progress);

            // 选择第一个流进行下载（简化版本）
            var selectedStream = streams.First();
            var segments = selectedStream.Playlist?.MediaParts?.FirstOrDefault()?.MediaSegments;

            if (segments == null || segments.Count == 0)
            {
                return new DownloadResult
                {
                    Success = false,
                    ErrorCode = -3,
                    ErrorMessage = "No segments found"
                };
            }

            // 下载分片
            var totalSegments = segments.Count;
            var completedSegments = 0;
            var downloadedBytes = 0L;
            var speedContainer = new SpeedContainer { SpeedLimit = config.MaxSpeed };

            var tempDir = Path.Combine(Path.GetTempPath(), $"m3u8dl_{Guid.NewGuid():N}");
            Directory.CreateDirectory(tempDir);

            var segmentFiles = new List<string>();

            foreach (var segment in segments)
            {
                if (_cancellationTokenSource.Token.IsCancellationRequested)
                {
                    UpdateProgress(DownloadStatus.Cancelled, 0, 0, 0, progress);
                    CleanupTempFiles(tempDir);
                    return new DownloadResult
                    {
                        Success = false,
                        ErrorCode = -4,
                        ErrorMessage = "Download cancelled"
                    };
                }

                // 下载分片
                var segmentPath = Path.Combine(tempDir, $"segment_{completedSegments:D6}.ts");
                var segmentData = await DownloadSegmentAsync(segment, config, _cancellationTokenSource.Token);
                
                if (segmentData != null)
                {
                    await File.WriteAllBytesAsync(segmentPath, segmentData, _cancellationTokenSource.Token);
                    segmentFiles.Add(segmentPath);
                    
                    downloadedBytes += segmentData.Length;
                    completedSegments++;

                    speedContainer.UpdateSpeed(downloadedBytes);

                    var percentage = (int)((completedSegments * 100.0) / totalSegments);
                    UpdateProgress(DownloadStatus.Downloading, percentage, downloadedBytes, 0, progress, 
                        completedSegments, totalSegments, speedContainer.CurrentSpeed);
                }
            }

            // 合并分片
            UpdateProgress(DownloadStatus.Merging, 95, downloadedBytes, 0, progress);

            if (config.AutoMerge)
            {
                await MergeSegmentsAsync(segmentFiles, config.OutputPath, _cancellationTokenSource.Token);
            }

            // 清理临时文件
            if (config.DeleteTempFiles)
            {
                CleanupTempFiles(tempDir);
            }

            // 完成
            var duration = (DateTime.Now - startTime).TotalSeconds;
            var averageSpeed = duration > 0 ? (long)(downloadedBytes / duration) : 0;

            UpdateProgress(DownloadStatus.Completed, 100, downloadedBytes, downloadedBytes, progress);

            return new DownloadResult
            {
                Success = true,
                OutputPath = config.OutputPath,
                FileSize = downloadedBytes,
                DurationSeconds = duration,
                AverageSpeed = averageSpeed,
                ErrorCode = 0
            };
        }
        catch (Exception ex)
        {
            UpdateProgress(DownloadStatus.Failed, 0, 0, 0, progress);
            
            return new DownloadResult
            {
                Success = false,
                ErrorCode = -99,
                ErrorMessage = ex.Message,
                DurationSeconds = (DateTime.Now - startTime).TotalSeconds
            };
        }
    }

    /// <summary>
    /// 取消下载
    /// </summary>
    public void Cancel()
    {
        _cancellationTokenSource?.Cancel();
    }

    /// <summary>
    /// 获取当前进度
    /// </summary>
    public DownloadProgress GetProgress()
    {
        return _currentProgress;
    }

    /// <summary>
    /// 配置 HttpClient
    /// </summary>
    private void ConfigureHttpClient(iOSDownloaderConfig config)
    {
        _httpClient.Timeout = TimeSpan.FromSeconds(config.TimeoutSeconds);

        if (!string.IsNullOrEmpty(config.UserAgent))
        {
            _httpClient.DefaultRequestHeaders.UserAgent.ParseAdd(config.UserAgent);
        }

        if (!string.IsNullOrEmpty(config.Referer))
        {
            _httpClient.DefaultRequestHeaders.Referrer = new Uri(config.Referer);
        }

        foreach (var header in config.Headers)
        {
            _httpClient.DefaultRequestHeaders.TryAddWithoutValidation(header.Key, header.Value);
        }
    }

    /// <summary>
    /// 创建解析器配置
    /// </summary>
    private ParserConfig CreateParserConfig(iOSDownloaderConfig config)
    {
        var parserConfig = new ParserConfig
        {
            BaseUrl = config.Url,
            Headers = config.Headers
        };

        return parserConfig;
    }

    /// <summary>
    /// 下载单个分片
    /// </summary>
    private async Task<byte[]?> DownloadSegmentAsync(
        MediaSegment segment, 
        iOSDownloaderConfig config, 
        CancellationToken cancellationToken)
    {
        var retryCount = 0;
        Exception? lastException = null;

        while (retryCount <= config.RetryCount)
        {
            try
            {
                var response = await _httpClient.GetAsync(segment.Url, cancellationToken);
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsByteArrayAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                lastException = ex;
                retryCount++;
                
                if (retryCount <= config.RetryCount)
                {
                    await Task.Delay(1000 * retryCount, cancellationToken);
                }
            }
        }

        Console.WriteLine($"Failed to download segment after {config.RetryCount} retries: {segment.Url}");
        return null;
    }

    /// <summary>
    /// 合并分片
    /// </summary>
    private async Task MergeSegmentsAsync(
        List<string> segmentFiles, 
        string outputPath, 
        CancellationToken cancellationToken)
    {
        var outputDir = Path.GetDirectoryName(outputPath);
        if (!string.IsNullOrEmpty(outputDir) && !Directory.Exists(outputDir))
        {
            Directory.CreateDirectory(outputDir);
        }

        using var outputStream = File.Create(outputPath);
        
        foreach (var segmentFile in segmentFiles)
        {
            if (cancellationToken.IsCancellationRequested)
                break;

            using var inputStream = File.OpenRead(segmentFile);
            await inputStream.CopyToAsync(outputStream, cancellationToken);
        }
    }

    /// <summary>
    /// 清理临时文件
    /// </summary>
    private void CleanupTempFiles(string tempDir)
    {
        try
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to cleanup temp files: {ex.Message}");
        }
    }

    /// <summary>
    /// 更新进度
    /// </summary>
    private void UpdateProgress(
        DownloadStatus status,
        int percentage,
        long downloadedBytes,
        long totalBytes,
        IProgress<DownloadProgress>? progress,
        int completedSegments = 0,
        int totalSegments = 0,
        long speed = 0)
    {
        _currentProgress = new DownloadProgress
        {
            Status = status,
            Percentage = percentage,
            DownloadedBytes = downloadedBytes,
            TotalBytes = totalBytes,
            CompletedSegments = completedSegments,
            TotalSegments = totalSegments,
            Speed = speed
        };

        progress?.Report(_currentProgress);
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
        _cancellationTokenSource?.Dispose();
    }
}
