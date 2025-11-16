namespace N_m3u8DL_RE.iOS.Entity;

/// <summary>
/// 下载进度信息
/// </summary>
public class DownloadProgress
{
    /// <summary>
    /// 进度百分比 (0-100)
    /// </summary>
    public int Percentage { get; set; }

    /// <summary>
    /// 已下载字节数
    /// </summary>
    public long DownloadedBytes { get; set; }

    /// <summary>
    /// 总字节数
    /// </summary>
    public long TotalBytes { get; set; }

    /// <summary>
    /// 下载速度 (字节/秒)
    /// </summary>
    public long Speed { get; set; }

    /// <summary>
    /// 已完成的分片数
    /// </summary>
    public int CompletedSegments { get; set; }

    /// <summary>
    /// 总分片数
    /// </summary>
    public int TotalSegments { get; set; }

    /// <summary>
    /// 下载状态
    /// </summary>
    public DownloadStatus Status { get; set; }

    /// <summary>
    /// 错误消息
    /// </summary>
    public string? ErrorMessage { get; set; }
}

/// <summary>
/// 下载状态
/// </summary>
public enum DownloadStatus
{
    /// <summary>
    /// 未开始
    /// </summary>
    NotStarted = 0,

    /// <summary>
    /// 初始化中
    /// </summary>
    Initializing = 1,

    /// <summary>
    /// 下载中
    /// </summary>
    Downloading = 2,

    /// <summary>
    /// 合并中
    /// </summary>
    Merging = 3,

    /// <summary>
    /// 已完成
    /// </summary>
    Completed = 4,

    /// <summary>
    /// 已取消
    /// </summary>
    Cancelled = 5,

    /// <summary>
    /// 失败
    /// </summary>
    Failed = 6
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
    public string? OutputPath { get; set; }

    /// <summary>
    /// 文件大小
    /// </summary>
    public long FileSize { get; set; }

    /// <summary>
    /// 下载耗时（秒）
    /// </summary>
    public double DurationSeconds { get; set; }

    /// <summary>
    /// 平均速度 (字节/秒)
    /// </summary>
    public long AverageSpeed { get; set; }

    /// <summary>
    /// 错误代码
    /// </summary>
    public int ErrorCode { get; set; }

    /// <summary>
    /// 错误消息
    /// </summary>
    public string? ErrorMessage { get; set; }
}

/// <summary>
/// 速度容器（用于速度计算）
/// </summary>
public class SpeedContainer
{
    private long _lastBytes = 0;
    private DateTime _lastTime = DateTime.Now;
    private readonly Queue<long> _speedHistory = new();
    private const int MaxHistorySize = 10;

    /// <summary>
    /// 速度限制 (字节/秒)，0 表示不限制
    /// </summary>
    public long SpeedLimit { get; set; } = 0;

    /// <summary>
    /// 当前速度 (字节/秒)
    /// </summary>
    public long CurrentSpeed { get; private set; }

    /// <summary>
    /// 更新速度
    /// </summary>
    public void UpdateSpeed(long currentBytes)
    {
        var now = DateTime.Now;
        var elapsed = (now - _lastTime).TotalSeconds;

        if (elapsed >= 1.0)
        {
            var speed = (long)((currentBytes - _lastBytes) / elapsed);
            _speedHistory.Enqueue(speed);

            if (_speedHistory.Count > MaxHistorySize)
            {
                _speedHistory.Dequeue();
            }

            CurrentSpeed = (long)_speedHistory.Average();
            _lastBytes = currentBytes;
            _lastTime = now;
        }
    }

    /// <summary>
    /// 重置
    /// </summary>
    public void Reset()
    {
        _lastBytes = 0;
        _lastTime = DateTime.Now;
        _speedHistory.Clear();
        CurrentSpeed = 0;
    }
}
