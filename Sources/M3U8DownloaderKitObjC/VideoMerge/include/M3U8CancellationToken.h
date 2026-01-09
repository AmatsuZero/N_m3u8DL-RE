//
//  M3U8CancellationToken.h
//  M3U8DownloaderKit
//
//  取消令牌
//  用于支持视频合并操作的取消功能
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 取消令牌
 * 
 * 用于控制异步操作的取消。
 * 调用者可以通过调用 cancel 方法来请求取消操作。
 * 执行者应该定期检查 isCancelled 属性，并在适当的时候停止操作。
 * 
 * 线程安全：此类是线程安全的，可以从任何线程调用。
 */
@interface M3U8CancellationToken : NSObject

/**
 * 是否已请求取消
 * 
 * 线程安全的属性，可以从任何线程读取。
 */
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;

/**
 * 请求取消操作
 * 
 * 此方法是线程安全的，可以从任何线程调用。
 * 调用后，isCancelled 属性将变为 YES。
 * 
 * 注意：此方法只是设置取消标志，实际的取消行为由执行者决定。
 */
- (void)cancel;

/**
 * 注册取消回调
 * 
 * 当取消被请求时，会调用此回调。
 * 如果在注册时已经被取消，回调会立即执行。
 * 
 * @param handler 取消时执行的回调，在主线程执行
 */
- (void)registerCancellationHandler:(void (^)(void))handler;

@end

NS_ASSUME_NONNULL_END
