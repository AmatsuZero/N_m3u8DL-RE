using N_m3u8DL_RE.Common.Entity;
using N_m3u8DL_RE.Core.Entity;

namespace N_m3u8DL_RE.Core.Downloader;

/// <summary>
/// 下载器接口
/// </summary>
public interface IDownloader
{
    /// <summary>
    /// 下载媒体分片
    /// </summary>
    /// <param name="segment">媒体分片信息</param>
    /// <param name="savePath">保存路径</param>
    /// <param name="speedContainer">速度容器</param>
    /// <param name="headers">HTTP请求头</param>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>下载结果</returns>
    Task<DownloadResult?> DownloadSegmentAsync(
        MediaSegment segment, 
        string savePath, 
        SpeedContainer speedContainer, 
        Dictionary<string, string>? headers = null,
        CancellationToken cancellationToken = default);
}
