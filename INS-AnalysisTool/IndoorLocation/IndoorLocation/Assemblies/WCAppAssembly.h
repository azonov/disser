//
// Created by Yaroslav Vorontsov on 01.06.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import Typhoon;

@class WCCoreProvider;
@class AppDelegate;
@class WCLoggingContext;
@class WCExperimentsViewController;

@interface WCAppAssembly : TyphoonAssembly
@property (strong, nonatomic, readonly) WCCoreProvider *coreProvider;
@property (strong, nonatomic, readonly) WCLoggingContext *loggingContext;

- (AppDelegate *)appDelegate;
@end