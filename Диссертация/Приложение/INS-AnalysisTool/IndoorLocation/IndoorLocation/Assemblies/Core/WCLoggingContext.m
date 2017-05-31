//
// Created by Yaroslav Vorontsov on 26.05.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import CocoaLumberjack;
#import "WCLoggingContext.h"
#import "ILConstants.h"
#import "WCLogFormatter.h"

@interface WCLoggingContext()
@property (strong, nonatomic, readonly) id<DDLogFormatter> sysLogFormatter;
@property (strong, nonatomic, readonly) id<DDLogger> systemLogger;
@property (strong, nonatomic, readonly) id<DDLogger> ttyLogger;
@end


@implementation WCLoggingContext
{
    id _sysLogFormatter;
    id _systemLogger;
    id _ttyLogger;
}

#pragma mark - Initialization

- (instancetype)init
{
    if ((self = [super init])) {
        [self setupLogging];
    }
    return self;
}

- (void)setupLogging
{
    // CocoaLumberjack initialization
    [DDLog addLogger:self.systemLogger];
    [DDLog addLogger:self.ttyLogger];
    DDLogDebug(@"Initialized CocoaLumberjack logging");
}

#pragma mark - Overridden getters/factory methods

- (id <DDLogFormatter>)sysLogFormatter
{
    if (!_sysLogFormatter) {
        _sysLogFormatter = [WCLogFormatter new];
    }
    return _sysLogFormatter;
}


- (id <DDLogger>)systemLogger
{
    if (!_systemLogger) {
        DDASLLogger *sysLogger = [DDASLLogger new];
        sysLogger.logFormatter = self.sysLogFormatter;
        _systemLogger = sysLogger;
    }
    return _systemLogger;
}

- (id <DDLogger>)ttyLogger
{
    // Look here https://github.com/CocoaLumberjack/CocoaLumberjack/blob/master/Documentation/AppCode-support.md
    // to enable AppCode colored console
    if (!_ttyLogger) {
        DDTTYLogger *ttyLogger = [DDTTYLogger new];
        ttyLogger.logFormatter = self.sysLogFormatter;
        ttyLogger.colorsEnabled = YES;
        _ttyLogger = ttyLogger;
    }
    return _ttyLogger;
}

@end