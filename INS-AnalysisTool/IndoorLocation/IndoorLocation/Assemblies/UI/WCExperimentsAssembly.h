//
// Created by Yaroslav Vorontsov on 29.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import Typhoon;

@class WCCoreProvider;

@interface WCExperimentsAssembly : TyphoonAssembly
@property (strong, nonatomic, readonly) WCCoreProvider *coreProvider;
- (UIViewController *)experimentsViewController;
@end