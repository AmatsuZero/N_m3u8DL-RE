using N_m3u8DL_RE.Common.Log;

namespace N_m3u8DL_RE.Core.Abstraction;

/// <summary>
/// 日志接口抽象，用于iOS平台的日志注入
/// </summary>
public interface ILogger
{
    /// <summary>
    /// 记录日志
    /// </summary>
    /// <param name="level">日志级别</param>
    /// <param name="message">日志消息</param>
    void Log(LogLevel level, string message);

    /// <summary>
    /// 记录调试日志
    /// </summary>
    void Debug(string message) => Log(LogLevel.DEBUG, message);

    /// <summary>
    /// 记录信息日志
    /// </summary>
    void Info(string message) => Log(LogLevel.INFO, message);

    /// <summary>
    /// 记录警告日志
    /// </summary>
    void Warn(string message) => Log(LogLevel.WARN, message);

    /// <summary>
    /// 记录错误日志
    /// </summary>
    void Error(string message) => Log(LogLevel.ERROR, message);
}

/// <summary>
/// 空日志实现，不输出任何日志
/// </summary>
public class NullLogger : ILogger
{
    public static readonly NullLogger Instance = new();

    private NullLogger() { }

    public void Log(LogLevel level, string message)
    {
        // 不做任何操作
    }
}
