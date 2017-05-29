//
// Created by Yaroslav Vorontsov on 09.02.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import "WCLogFormatter.h"


@implementation WCLogFormatter
{

}

+ (NSDateFormatter *)dateFormatter {
    static dispatch_once_t once_t = 0;
    static NSDateFormatter *dateFormatter = nil;
    dispatch_once(&once_t, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"YYYY-MM-dd HH:mm:ss Z";
    });
    return dateFormatter;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel;
    switch (logMessage.flag) {
        case DDLogFlagError : logLevel = @"ERROR"; break;
        case DDLogFlagWarning  : logLevel = @"WARNING"; break;
        case DDLogFlagInfo  : logLevel = @"INFO"; break;
        case DDLogFlagDebug : logLevel = @"DEBUG"; break;
        default             : logLevel = @"VERBOSE"; break;
    }
    return [NSString stringWithFormat:@"%@|%@|%@:L%tu %@|%@",
                                      [[self.class dateFormatter] stringFromDate:logMessage.timestamp],
                                      logLevel,
                                      logMessage.fileName,
                                      logMessage.line,
                                      logMessage.function,
                                      logMessage.message];
}

@end