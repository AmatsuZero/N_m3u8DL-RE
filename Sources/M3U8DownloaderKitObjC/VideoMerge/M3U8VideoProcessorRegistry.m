//
//  M3U8VideoProcessorRegistry.m
//  M3U8DownloaderKit
//
//  视频处理器注册表实现
//

#import "M3U8VideoProcessorRegistry.h"
#import "M3U8VideoProcessor.h"

@interface M3U8VideoProcessorRegistry ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<M3U8VideoProcessor>> *processors;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation M3U8VideoProcessorRegistry

+ (instancetype)sharedRegistry {
    static M3U8VideoProcessorRegistry *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _processors = [NSMutableDictionary dictionary];
        _queue = dispatch_queue_create("com.m3u8downloader.processor.registry", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)registerProcessor:(id<M3U8VideoProcessor>)processor {
    if (!processor || !processor.name) {
        NSLog(@"[M3U8VideoProcessorRegistry] 无法注册处理器：处理器或名称为空");
        return;
    }
    
    dispatch_sync(self.queue, ^{
        self.processors[processor.name] = processor;
        NSLog(@"[M3U8VideoProcessorRegistry] 已注册处理器: %@ (优先级: %ld)", processor.name, (long)processor.priority);
    });
}

- (void)unregisterProcessorWithName:(NSString *)processorName {
    if (!processorName) {
        return;
    }
    
    dispatch_sync(self.queue, ^{
        [self.processors removeObjectForKey:processorName];
        NSLog(@"[M3U8VideoProcessorRegistry] 已注销处理器: %@", processorName);
    });
}

- (void)getAvailableProcessorsWithCompletion:(void (^)(NSArray<id<M3U8VideoProcessor>> *))completion {
    if (!completion) {
        return;
    }
    
    // 获取所有处理器的副本
    __block NSArray<id<M3U8VideoProcessor>> *allProcessors = nil;
    dispatch_sync(self.queue, ^{
        allProcessors = [self.processors.allValues copy];
    });
    
    // 按优先级降序排序
    allProcessors = [allProcessors sortedArrayUsingComparator:^NSComparisonResult(id<M3U8VideoProcessor> obj1, id<M3U8VideoProcessor> obj2) {
        if (obj1.priority > obj2.priority) {
            return NSOrderedAscending;
        } else if (obj1.priority < obj2.priority) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    // 异步检查每个处理器的可用性
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray<id<M3U8VideoProcessor>> *availableProcessors = [NSMutableArray array];
    NSLock *lock = [[NSLock alloc] init];
    
    for (id<M3U8VideoProcessor> processor in allProcessors) {
        dispatch_group_enter(group);
        [processor isAvailableWithCompletion:^(BOOL available) {
            if (available) {
                [lock lock];
                [availableProcessors addObject:processor];
                [lock unlock];
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 再次按优先级排序
        NSArray<id<M3U8VideoProcessor>> *sortedProcessors = [availableProcessors sortedArrayUsingComparator:^NSComparisonResult(id<M3U8VideoProcessor> obj1, id<M3U8VideoProcessor> obj2) {
            if (obj1.priority > obj2.priority) {
                return NSOrderedAscending;
            } else if (obj1.priority < obj2.priority) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
        completion(sortedProcessors);
    });
}

- (id<M3U8VideoProcessor>)getProcessorByName:(NSString *)name {
    if (!name) {
        return nil;
    }
    
    __block id<M3U8VideoProcessor> processor = nil;
    dispatch_sync(self.queue, ^{
        processor = self.processors[name];
    });
    return processor;
}

- (void)getProcessorsByFeature:(NSString *)feature completion:(void (^)(NSArray<id<M3U8VideoProcessor>> *))completion {
    if (!completion) {
        return;
    }
    
    [self getAvailableProcessorsWithCompletion:^(NSArray<id<M3U8VideoProcessor>> *processors) {
        NSMutableArray<id<M3U8VideoProcessor>> *supportedProcessors = [NSMutableArray array];
        for (id<M3U8VideoProcessor> processor in processors) {
            if ([processor supportsFeature:feature]) {
                [supportedProcessors addObject:processor];
            }
        }
        completion(supportedProcessors);
    }];
}

- (void)isFeatureSupported:(NSString *)feature completion:(void (^)(BOOL))completion {
    if (!completion) {
        return;
    }
    
    [self getProcessorsByFeature:feature completion:^(NSArray<id<M3U8VideoProcessor>> *processors) {
        completion(processors.count > 0);
    }];
}

- (void)getBestProcessorWithCompletion:(void (^)(id<M3U8VideoProcessor> _Nullable))completion {
    if (!completion) {
        return;
    }
    
    [self getAvailableProcessorsWithCompletion:^(NSArray<id<M3U8VideoProcessor>> *processors) {
        completion(processors.firstObject);
    }];
}

- (NSArray<NSString *> *)getAllProcessorNames {
    __block NSArray<NSString *> *names = nil;
    dispatch_sync(self.queue, ^{
        names = [self.processors.allKeys copy];
    });
    return names ?: @[];
}

- (void)clearAllProcessors {
    dispatch_sync(self.queue, ^{
        [self.processors removeAllObjects];
        NSLog(@"[M3U8VideoProcessorRegistry] 已清空所有处理器");
    });
}

@end
