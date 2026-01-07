using N_m3u8DL_RE.Core.Abstraction;

namespace N_m3u8DL_RE.Core.VideoProcessor;

/// <summary>
/// 基础视频处理器 - 纯C#实现，不依赖外部工具
/// </summary>
public class BasicVideoProcessor : IVideoProcessor
{
    private readonly ILogger _logger;

    public string Name => "BasicVideoProcessor";
    public int Priority => 1; // 最低优先级

    public BasicVideoProcessor(ILogger? logger = null)
    {
        _logger = logger ?? NullLogger.Instance;
    }

    public Task<bool> IsAvailableAsync()
    {
        // 基础处理器始终可用
        return Task.FromResult(true);
    }

    public Task<DecryptionResult> DecryptAsync(DecryptionRequest request, CancellationToken cancellationToken = default)
    {
        _logger.Warn($"[{Name}] Decryption is not supported in basic processor");
        return Task.FromResult(new DecryptionResult
        {
            Success = false,
            ErrorMessage = "Decryption is not supported in basic processor. Please use a processor with decryption capabilities."
        });
    }

    public Task<List<MediaInfo>> ReadMediaInfoAsync(string filePath, CancellationToken cancellationToken = default)
    {
        _logger.Warn($"[{Name}] Media info reading is not fully supported in basic processor");
        
        // 返回基本文件信息
        var fileInfo = new FileInfo(filePath);
        var mediaInfo = new MediaInfo
        {
            Type = "unknown",
            Properties = new Dictionary<string, string>
            {
                ["FilePath"] = filePath,
                ["FileSize"] = fileInfo.Length.ToString(),
                ["Extension"] = fileInfo.Extension
            }
        };

        return Task.FromResult(new List<MediaInfo> { mediaInfo });
    }

    public Task<MergeResult> MergeAsync(MergeRequest request, CancellationToken cancellationToken = default)
    {
        _logger.Info($"[{Name}] Merging {request.InputFiles.Count} files using basic concatenation");

        try
        {
            // 简单的文件拼接
            using var outputStream = new FileStream(request.OutputFile, FileMode.Create, FileAccess.Write);
            foreach (var inputFile in request.InputFiles)
            {
                cancellationToken.ThrowIfCancellationRequested();
                
                using var inputStream = new FileStream(inputFile, FileMode.Open, FileAccess.Read);
                inputStream.CopyTo(outputStream);
            }

            _logger.Info($"[{Name}] Merge completed: {request.OutputFile}");
            return Task.FromResult(new MergeResult
            {
                Success = true,
                OutputFile = request.OutputFile
            });
        }
        catch (Exception ex)
        {
            _logger.Error($"[{Name}] Merge failed: {ex.Message}");
            return Task.FromResult(new MergeResult
            {
                Success = false,
                ErrorMessage = ex.Message
            });
        }
    }

    public bool SupportsFeature(string feature)
    {
        return feature.ToLower() switch
        {
            "merge" => true,
            "basic_concat" => true,
            _ => false
        };
    }
}
