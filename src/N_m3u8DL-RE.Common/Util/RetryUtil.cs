using System.Net;
using N_m3u8DL_RE.Common.Log;
#if !IOS
using Spectre.Console;
#endif

namespace N_m3u8DL_RE.Common.Util;

public static class RetryUtil
{
    public static async Task<T?> WebRequestRetryAsync<T>(Func<Task<T>> funcAsync, int maxRetries = 10, int retryDelayMilliseconds = 1500, int retryDelayIncrementMilliseconds = 0)
    {
        var retryCount = 0;
        var result = default(T);
        Exception currentException = new();

        while (retryCount < maxRetries)
        {
            try
            {
                result = await funcAsync();
                break;
            }
            catch (Exception ex) when (ex is WebException or IOException or HttpRequestException)
            {
                currentException = ex;
                retryCount++;
#if IOS
                Logger.WarnMarkUp($"{ex.Message} ({retryCount}/{maxRetries})");
#else
                Logger.WarnMarkUp($"[grey]{ex.Message.EscapeMarkup()} ({retryCount}/{maxRetries})[/]");
#endif
                await Task.Delay(retryDelayMilliseconds + (retryDelayIncrementMilliseconds * (retryCount - 1)));
            }
        }

        if (retryCount == maxRetries)
        {
            throw new Exception($"Failed to execute action after {maxRetries} retries.", currentException);
        }

        return result;
    }
}