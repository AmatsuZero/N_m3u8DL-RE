namespace N_m3u8DL_RE.Core.VideoProcessor;

/// <summary>
/// 视频处理器接口 - 支持多种后端实现
/// </summary>
public interface IVideoProcessor
{
    /// <summary>
    /// 处理器名称
    /// </summary>
    string Name { get; }

    /// <summary>
    /// 处理器优先级（数值越大优先级越高）
    /// </summary>
    int Priority { get; }

    /// <summary>
    /// 检查处理器是否可用
    /// </summary>
    /// <returns>是否可用</returns>
    Task<bool> IsAvailableAsync();

    /// <summary>
    /// 解密MP4文件
    /// </summary>
    /// <param name="request">解密请求</param>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>解密结果</returns>
    Task<DecryptionResult> DecryptAsync(DecryptionRequest request, CancellationToken cancellationToken = default);

    /// <summary>
    /// 读取媒体信息
    /// </summary>
    /// <param name="filePath">文件路径</param>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>媒体信息列表</returns>
    Task<List<MediaInfo>> ReadMediaInfoAsync(string filePath, CancellationToken cancellationToken = default);

    /// <summary>
    /// 合并多个文件
    /// </summary>
    /// <param name="request">合并请求</param>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>合并结果</returns>
    Task<MergeResult> MergeAsync(MergeRequest request, CancellationToken cancellationToken = default);

    /// <summary>
    /// 检查是否支持特定功能
    /// </summary>
    /// <param name="feature">功能名称</param>
    /// <returns>是否支持</returns>
    bool SupportsFeature(string feature);
}

/// <summary>
/// 解密请求
/// </summary>
public class DecryptionRequest
{
    /// <summary>
    /// 源文件路径
    /// </summary>
    public required string SourceFile { get; set; }

    /// <summary>
    /// 目标文件路径
    /// </summary>
    public required string DestinationFile { get; set; }

    /// <summary>
    /// 密钥列表（格式：KID:KEY）
    /// </summary>
    public required string[] Keys { get; set; }

    /// <summary>
    /// KID（Key ID）
    /// </summary>
    public string? Kid { get; set; }

    /// <summary>
    /// 初始化文件路径
    /// </summary>
    public string? InitFile { get; set; }

    /// <summary>
    /// 是否为多DRM
    /// </summary>
    public bool IsMultiDRM { get; set; }

    /// <summary>
    /// Track ID
    /// </summary>
    public string? TrackId { get; set; }
}

/// <summary>
/// 解密结果
/// </summary>
public class DecryptionResult
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
    /// 输出文件路径
    /// </summary>
    public string? OutputFile { get; set; }
}

/// <summary>
/// 媒体信息
/// </summary>
public class MediaInfo
{
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
    /// 时长（秒）
    /// </summary>
    public double? Duration { get; set; }

    /// <summary>
    /// 宽度（视频）
    /// </summary>
    public int? Width { get; set; }

    /// <summary>
    /// 高度（视频）
    /// </summary>
    public int? Height { get; set; }

    /// <summary>
    /// 帧率（视频）
    /// </summary>
    public double? FrameRate { get; set; }

    /// <summary>
    /// 采样率（音频）
    /// </summary>
    public int? SampleRate { get; set; }

    /// <summary>
    /// 声道数（音频）
    /// </summary>
    public int? Channels { get; set; }

    /// <summary>
    /// 语言
    /// </summary>
    public string? Language { get; set; }

    /// <summary>
    /// 其他属性
    /// </summary>
    public Dictionary<string, string> Properties { get; set; } = new();
}

/// <summary>
/// 合并请求
/// </summary>
public class MergeRequest
{
    /// <summary>
    /// 输入文件列表
    /// </summary>
    public required List<string> InputFiles { get; set; }

    /// <summary>
    /// 输出文件路径
    /// </summary>
    public required string OutputFile { get; set; }

    /// <summary>
    /// 合并选项
    /// </summary>
    public Dictionary<string, string> Options { get; set; } = new();
}

/// <summary>
/// 合并结果
/// </summary>
public class MergeResult
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
    /// 输出文件路径
    /// </summary>
    public string? OutputFile { get; set; }
}
