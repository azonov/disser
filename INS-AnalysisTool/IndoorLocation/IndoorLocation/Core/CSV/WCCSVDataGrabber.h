//
// Created by Yaroslav Vorontsov on 01.06.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import CocoaLumberjack;

@protocol WCCSVDataGrabber <NSObject>
@property (copy, nonatomic, readwrite) NSString *fileName;
- (void)writeValues:(NSArray *)values;
- (void)flushLogs;
@end

@interface WCCSVDataGrabber : NSObject <WCCSVDataGrabber>
@end