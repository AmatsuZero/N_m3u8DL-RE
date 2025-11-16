namespace N_m3u8DL_RE.iOS.Config;

/// <summary>
/// iOS 下载器配置
/// 简化版本，不依赖主项目的 MyOption
/// </summary>
public class iOSDownloaderConfig
{
    /// <summary>
    /// 下载 URL
    /// </summary>
    public required string Url { get; set; }

    /// <summary>
    /// 输出路径
    /// </summary>
    public required string OutputPath { get; set; }

    /// <summary>
    /// 最大并发数
    /// </summary>
    public int MaxThreads { get; set; } = 8;

    /// <summary>
    /// 最大速度限制 (字节/秒)，0 表示不限制
    /// </summary>
    public long MaxSpeed { get; set; } = 0;

    /// <summary>
    /// 重试次数
    /// </summary>
    public int RetryCount { get; set; } = 3;

    /// <summary>
    /// 超时时间（秒）
    /// </summary>
    public int TimeoutSeconds { get; set; } = 30;

    /// <summary>
    /// 自定义请求头
    /// </summary>
    public Dictionary<string, string> Headers { get; set; } = new();

    /// <summary>
    /// 是否自动合并
    /// </summary>
    public bool AutoMerge { get; set; } = true;

    /// <summary>
    /// 是否删除临时文件
    /// </summary>
    public bool DeleteTempFiles { get; set; } = true;

    /// <summary>
    /// 代理地址
    /// </summary>
    public string? ProxyUrl { get; set; }

    /// <summary>
    /// User-Agent
    /// </summary>
    public string? UserAgent { get; set; }

    /// <summary>
    /// Referer
    /// </summary>
    public string? Referer { get; set; }

    /// <summary>
    /// Cookie
    /// </summary>
    public string? Cookie { get; set; }

    /// <summary>
    /// 是否跳过证书验证
    /// </summary>
    public bool SkipCertificateValidation { get; set; } = false;

    /// <summary>
    /// 日志级别 (0=None, 1=Error, 2=Warning, 3=Info, 4=Debug)
    /// </summary>
    public int LogLevel { get; set; } = 3;

    /// <summary>
    /// 验证配置是否有效
    /// </summary>
    public bool IsValid()
    {
        return !string.IsNullOrWhiteSpace(Url) && 
               !string.IsNullOrWhiteSpace(OutputPath) &&
               MaxThreads > 0 &&
               RetryCount >= 0 &&
               TimeoutSeconds > 0;
    }

    /// <summary>
    /// 获取配置摘要
    /// </summary>
    public string GetSummary()
    {
        return $"URL: {Url}, Output: {OutputPath}, Threads: {MaxThreads}, Retry: {RetryCount}";
    }
}
