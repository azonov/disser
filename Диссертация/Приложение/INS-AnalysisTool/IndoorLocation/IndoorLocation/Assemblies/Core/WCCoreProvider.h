//
// Created by Yaroslav Vorontsov on 01.06.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import Typhoon;

@protocol WCBeaconRanger;
@protocol WCCSVDataGrabber;
@protocol WCSensorFusion;
@protocol WCDiscoveryManager;

@interface WCCoreProvider : TyphoonAssembly
- (id<WCBeaconRanger>)rangingService;
- (id<WCCSVDataGrabber>)logGatheringService;
- (id<WCSensorFusion>)sensorService;
- (id<WCDiscoveryManager>)discoveryService;
@end