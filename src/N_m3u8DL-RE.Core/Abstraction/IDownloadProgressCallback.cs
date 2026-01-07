namespace N_m3u8DL_RE.Core.Abstraction;

/// <summary>
/// 下载进度信息
/// </summary>
public class DownloadProgress
{
    /// <summary>
    /// 任务ID
    /// </summary>
    public int TaskId { get; set; }

    /// <summary>
    /// 任务描述
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// 当前进度值
    /// </summary>
    public int CurrentValue { get; set; }

    /// <summary>
    /// 最大进度值
    /// </summary>
    public int MaxValue { get; set; }

    /// <summary>
    /// 进度百分比 (0-100)
    /// </summary>
    public double Percentage => MaxValue > 0 ? (double)CurrentValue / MaxValue * 100 : 0;

    /// <summary>
    /// 下载速度 (字节/秒)
    /// </summary>
    public long Speed { get; set; }

    /// <summary>
    /// 已下载大小 (字节)
    /// </summary>
    public long DownloadedBytes { get; set; }

    /// <summary>
    /// 总大小 (字节)
    /// </summary>
    public long TotalBytes { get; set; }

    /// <summary>
    /// 是否已完成
    /// </summary>
    public bool IsCompleted => CurrentValue >= MaxValue;

    /// <summary>
    /// 是否失败
    /// </summary>
    public bool IsFailed { get; set; }

    /// <summary>
    /// 错误消息
    /// </summary>
    public string? ErrorMessage { get; set; }
}

/// <summary>
/// 下载进度回调接口
/// </summary>
public interface IDownloadProgressCallback
{
    /// <summary>
    /// 进度更新回调
    /// </summary>
    /// <param name="progress">进度信息</param>
    void OnProgressUpdate(DownloadProgress progress);

    /// <summary>
    /// 下载开始回调
    /// </summary>
    /// <param name="taskId">任务ID</param>
    /// <param name="description">任务描述</param>
    void OnDownloadStarted(int taskId, string description);

    /// <summary>
    /// 下载完成回调
    /// </summary>
    /// <param name="taskId">任务ID</param>
    /// <param name="success">是否成功</param>
    void OnDownloadCompleted(int taskId, bool success);

    /// <summary>
    /// 下载失败回调
    /// </summary>
    /// <param name="taskId">任务ID</param>
    /// <param name="errorMessage">错误消息</param>
    void OnDownloadFailed(int taskId, string errorMessage);
}

/// <summary>
/// 空进度回调实现，不做任何操作
/// </summary>
public class NullProgressCallback : IDownloadProgressCallback
{
    public static readonly NullProgressCallback Instance = new();

    private NullProgressCallback() { }

    public void OnProgressUpdate(DownloadProgress progress) { }

    public void OnDownloadStarted(int taskId, string description) { }

    public void OnDownloadCompleted(int taskId, bool success) { }

    public void OnDownloadFailed(int taskId, string errorMessage) { }
}
