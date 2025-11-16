using N_m3u8DL_RE.iOS.Config;
using N_m3u8DL_RE.iOS.Entity;

namespace N_m3u8DL_RE.iOS.Downloader;

/// <summary>
/// iOS 下载器接口
/// </summary>
public interface IiOSDownloader
{
    /// <summary>
    /// 开始下载
    /// </summary>
    Task<DownloadResult> DownloadAsync(iOSDownloaderConfig config, IProgress<DownloadProgress>? progress = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// 取消下载
    /// </summary>
    void Cancel();

    /// <summary>
    /// 获取当前进度
    /// </summary>
    DownloadProgress GetProgress();
}
