//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import CocoaLumberjack;
@import libextobjc;
#import "WCCoreBluetoothOperation.h"
#import "ILConstants.h"


@interface WCCoreBluetoothOperation()
@property (strong, nonatomic, readonly) NSRecursiveLock *stateLock;
- (void)changeStateVariables:(NSArray<NSString *> *)variableNames withBlock:(void (^)())block;
@end

// http://lorenzoboaro.io/2016/01/05/having-fun-with-operation-in-ios.html
@implementation WCCoreBluetoothOperation
{
    BOOL _cancelled;
    BOOL _executing;
    BOOL _finished;
}

#pragma mark - Initialization

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
{
    if ((self = [super init])) {
        _stateLock = [[NSRecursiveLock alloc] init];
        _cancelled = NO;
        _executing = NO;
        _finished = NO;
        _peripheral = peripheral;
        _results = [@{} mutableCopy];
        self.name = NSStringFromClass([self class]);
    }
    return self;
}

#pragma mark - Configuration

- (instancetype)setCompletionCallback:(WCCoreBluetoothOperationCompletionBlock)callback
{
    NSParameterAssert(callback != nil);
    @weakify(self);
    self.completionBlock = ^{
        @strongify(self);
        callback(self.results);
    };
    return self;
}

#pragma mark - Lifecycle methods

- (void)start
{
    if (!self.cancelled) {
        [self changeStateVariables:@[@"isExecuting"] withBlock:^{
            DDLogInfo(@"Operation %@ has started", self.name);
            _executing = YES;
        }];
        [self main];
    } else {
        [self finish];
    }
}

- (void)main
{
    DDLogWarn(@"Should be overridden in subclasses. Do not call [super implementation]");
    [self finish];
}

- (void)finish
{
    [self changeStateVariables:@[@"isExecuting", @"isFinished"] withBlock:^{
        DDLogInfo(@"Operation %@ has finished", self.name);
        _executing = NO;
        _finished = YES;
    }];
}

- (void)cancel
{
    [self changeStateVariables:@[@"isCancelled"] withBlock:^{
        DDLogInfo(@"Operation %@ has been cancelled", self.name);
        _cancelled = YES;
    }];
    [super cancel];
}

#pragma mark - Operation state management

- (void)changeStateVariables:(NSArray<NSString *> *)variableNames withBlock:(void (^)())block
{
    NSParameterAssert(block != nil);
    [self.stateLock lock];
    [variableNames enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        [self willChangeValueForKey:obj];
    }];
    DDLogDebug(@"Changing state for the following properties: %@", [variableNames componentsJoinedByString:@", "]);
    block();
    [variableNames enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        [self didChangeValueForKey:obj];
    }];
    [self.stateLock unlock];
}

#pragma mark - Operation state flags

- (BOOL)isAsynchronous
{
    return YES;
}

- (BOOL)isCancelled
{
    return _cancelled;
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

@end