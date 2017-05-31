//
// Created by Yaroslav Vorontsov on 01.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import libextobjc;
@import CocoaLumberjack;
#import "WCHardwareSelectionInteractor.h"
#import "CollectionUtils.h"
#import "HardwareDescription.h"

@interface WCHardwareSelectionInteractor()
@property (strong, nonatomic, readonly) NSBundle *currentBundle;
@property (strong, nonatomic, readonly) NSBundle *hardwareBundle;
@end

@implementation WCHardwareSelectionInteractor
{
    NSBundle *_currentBundle;
    NSBundle *_hardwareBundle;
}

#pragma mark - Overridden getters/setters

- (NSBundle *)currentBundle
{
    if (!_currentBundle) {
        _currentBundle = [NSBundle bundleForClass:self.class];
    }
    return _currentBundle;
}

- (NSBundle *)hardwareBundle
{
    if (!_hardwareBundle) {
        NSString *path = [self.currentBundle pathForResource:@"Hardware" ofType:@"bundle"];
        _hardwareBundle = [NSBundle bundleWithPath:path];
    }
    return _hardwareBundle;
}


#pragma mark - Actions

- (void)fetchHardwareWithCompletion:(SimpleBlock)block
{
    @weakify(self);
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        @strongify(self);
        NSArray *allPaths = [self.hardwareBundle pathsForResourcesOfType:@"plist" inDirectory:@""];
        self->_models = [[allPaths map:^id(NSString *path) {
            return [NSDictionary dictionaryWithContentsOfFile:path];
        }] map:^id(NSDictionary *dict) {
            return [[HardwareDescription alloc] initWithDictionary:dict];
        }];
        DDLogDebug(@"Fetched beacon hardware information: %@", self.models);
    }];
    NSBlockOperation *callbackOperation = [NSBlockOperation blockOperationWithBlock:block];
    [callbackOperation addDependency:blockOperation];
    [self.workQueue addOperation:blockOperation];
    [self.callbackQueue addOperation:callbackOperation];
}

@end