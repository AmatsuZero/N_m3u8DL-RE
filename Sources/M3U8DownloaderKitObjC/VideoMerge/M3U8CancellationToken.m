//
//  M3U8CancellationToken.m
//  M3U8DownloaderKit
//
//  取消令牌实现
//

#import "M3U8CancellationToken.h"

@interface M3U8CancellationToken ()
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, strong) NSMutableArray<void (^)(void)> *handlers;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation M3U8CancellationToken

- (instancetype)init {
    self = [super init];
    if (self) {
        _cancelled = NO;
        _handlers = [NSMutableArray array];
        _queue = dispatch_queue_create("com.m3u8downloader.cancellation", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)cancel {
    __block NSArray<void (^)(void)> *handlersToCall = nil;
    
    dispatch_sync(self.queue, ^{
        if (!self.cancelled) {
            self.cancelled = YES;
            handlersToCall = [self.handlers copy];
            [self.handlers removeAllObjects];
        }
    });
    
    // 在主线程执行回调
    if (handlersToCall.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (void (^handler)(void) in handlersToCall) {
                handler();
            }
        });
    }
}

- (void)registerCancellationHandler:(void (^)(void))handler {
    if (!handler) {
        return;
    }
    
    __block BOOL shouldCallImmediately = NO;
    
    dispatch_sync(self.queue, ^{
        if (self.cancelled) {
            shouldCallImmediately = YES;
        } else {
            [self.handlers addObject:handler];
        }
    });
    
    if (shouldCallImmediately) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler();
        });
    }
}

@end
