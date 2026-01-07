using N_m3u8DL_RE.Core.Abstraction;

namespace N_m3u8DL_RE.Core.VideoProcessor;

/// <summary>
/// 视频处理器工厂 - 管理和选择视频处理器
/// </summary>
public class VideoProcessorFactory
{
    private readonly List<IVideoProcessor> _processors = new();
    private readonly ILogger _logger;
    private IVideoProcessor? _selectedProcessor;

    public VideoProcessorFactory(ILogger? logger = null)
    {
        _logger = logger ?? NullLogger.Instance;
    }

    /// <summary>
    /// 注册视频处理器
    /// </summary>
    /// <param name="processor">处理器实例</param>
    public void RegisterProcessor(IVideoProcessor processor)
    {
        _processors.Add(processor);
        _logger.Info($"Registered video processor: {processor.Name} (Priority: {processor.Priority})");
    }

    /// <summary>
    /// 自动选择最佳可用的处理器
    /// </summary>
    /// <returns>选择的处理器</returns>
    public async Task<IVideoProcessor> SelectBestProcessorAsync()
    {
        if (_selectedProcessor != null)
        {
            return _selectedProcessor;
        }

        _logger.Info("Selecting best available video processor...");

        // 按优先级排序
        var sortedProcessors = _processors.OrderByDescending(p => p.Priority).ToList();

        foreach (var processor in sortedProcessors)
        {
            _logger.Debug($"Checking processor: {processor.Name}");
            if (await processor.IsAvailableAsync())
            {
                _selectedProcessor = processor;
                _logger.Info($"Selected video processor: {processor.Name}");
                return processor;
            }
        }

        throw new InvalidOperationException("No available video processor found. Please register at least one processor.");
    }

    /// <summary>
    /// 根据名称获取处理器
    /// </summary>
    /// <param name="name">处理器名称</param>
    /// <returns>处理器实例</returns>
    public IVideoProcessor? GetProcessorByName(string name)
    {
        return _processors.FirstOrDefault(p => p.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
    }

    /// <summary>
    /// 获取支持特定功能的处理器
    /// </summary>
    /// <param name="feature">功能名称</param>
    /// <returns>支持该功能的处理器列表</returns>
    public async Task<List<IVideoProcessor>> GetProcessorsByFeatureAsync(string feature)
    {
        var result = new List<IVideoProcessor>();

        foreach (var processor in _processors.OrderByDescending(p => p.Priority))
        {
            if (processor.SupportsFeature(feature) && await processor.IsAvailableAsync())
            {
                result.Add(processor);
            }
        }

        return result;
    }

    /// <summary>
    /// 重置选择的处理器
    /// </summary>
    public void ResetSelection()
    {
        _selectedProcessor = null;
        _logger.Debug("Processor selection reset");
    }

    /// <summary>
    /// 获取所有已注册的处理器
    /// </summary>
    /// <returns>处理器列表</returns>
    public List<IVideoProcessor> GetAllProcessors()
    {
        return new List<IVideoProcessor>(_processors);
    }

    /// <summary>
    /// 检查功能可用性
    /// </summary>
    /// <param name="feature">功能名称</param>
    /// <returns>是否有处理器支持该功能</returns>
    public async Task<bool> IsFeatureAvailableAsync(string feature)
    {
        var processors = await GetProcessorsByFeatureAsync(feature);
        return processors.Count > 0;
    }
}

/// <summary>
/// 视频处理器管理器 - 提供统一的视频处理接口
/// </summary>
public class VideoProcessorManager
{
    private readonly VideoProcessorFactory _factory;
    private readonly ILogger _logger;

    public VideoProcessorManager(VideoProcessorFactory factory, ILogger? logger = null)
    {
        _factory = factory;
        _logger = logger ?? NullLogger.Instance;
    }

    /// <summary>
    /// 解密文件
    /// </summary>
    /// <param name="request">解密请求</param>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>解密结果</returns>
    public async Task<DecryptionResult> DecryptAsync(DecryptionRequest request, CancellationToken cancellationToken = default)
    {
        var processors = await _factory.GetProcessorsByFeatureAsync("decrypt");
        
        if (processors.Count == 0)
        {
            _logger.Warn("No processor supports decryption feature");
            return new DecryptionResult
            {
                Success = false,
                ErrorMessage = "No processor supports decryption feature"
            };
        }

        // 尝试使用优先级最高的处理器
        foreach (var processor in processors)
        {
            _logger.Info($"Attempting decryption with {processor.Name}");
            var result = await processor.DecryptAsync(request, cancellationToken);
            
            if (result.Success)
            {
                _logger.Info($"Decryption succeeded with {processor.Name}");
                return result;
            }
            
            _logger.Warn($"Decryption failed with {processor.Name}: {result.ErrorMessage}");
        }

        return new DecryptionResult
        {
            Success = false,
            ErrorMessage = "All decryption attempts failed"
        };
    }

    /// <summary>
    /// 读取媒体信息
    /// </summary>
    /// <param name="filePath">文件路径</param>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>媒体信息列表</returns>
    public async Task<List<MediaInfo>> ReadMediaInfoAsync(string filePath, CancellationToken cancellationToken = default)
    {
        var processor = await _factory.SelectBestProcessorAsync();
        return await processor.ReadMediaInfoAsync(filePath, cancellationToken);
    }

    /// <summary>
    /// 合并文件
    /// </summary>
    /// <param name="request">合并请求</param>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>合并结果</returns>
    public async Task<MergeResult> MergeAsync(MergeRequest request, CancellationToken cancellationToken = default)
    {
        var processors = await _factory.GetProcessorsByFeatureAsync("merge");
        
        if (processors.Count == 0)
        {
            _logger.Warn("No processor supports merge feature");
            return new MergeResult
            {
                Success = false,
                ErrorMessage = "No processor supports merge feature"
            };
        }

        // 使用优先级最高的处理器
        var processor = processors.First();
        _logger.Info($"Merging with {processor.Name}");
        return await processor.MergeAsync(request, cancellationToken);
    }

    /// <summary>
    /// 检查功能是否可用
    /// </summary>
    /// <param name="feature">功能名称</param>
    /// <returns>是否可用</returns>
    public async Task<bool> IsFeatureAvailableAsync(string feature)
    {
        return await _factory.IsFeatureAvailableAsync(feature);
    }
}
