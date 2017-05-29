//
// Created by Yaroslav Vorontsov on 01.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCInteractor.h"


@implementation WCInteractor
{

}


+ (NSOperationQueue *)defaultWorkQueue
{
    static dispatch_once_t once_t = 0;
    static NSOperationQueue *workQueue = nil;
    dispatch_once(&once_t, ^{
        workQueue = [NSOperationQueue new];
        workQueue.maxConcurrentOperationCount = [NSProcessInfo processInfo].activeProcessorCount * 2;
        workQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    });
    return workQueue;
}

- (instancetype)init
{
    return [self initWithWorkQueue:[self.class defaultWorkQueue] callbackQueue:[NSOperationQueue mainQueue]];
}

- (instancetype)initWithWorkQueue:(NSOperationQueue *)workQueue callbackQueue:(NSOperationQueue *)callbackQueue
{
    if ((self = [super init])) {
        _workQueue = workQueue;
        _callbackQueue = callbackQueue;
    }
    return self;
}


@end