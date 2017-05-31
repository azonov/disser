//
// Created by Yaroslav Vorontsov on 29.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import UIKit;

@protocol WCDiscoveryManager;
@protocol HardwareInfo;

@interface WCBeaconListViewController : UIViewController
@property (strong, nonatomic, readonly) id<WCDiscoveryManager> discoveryService;
@property (strong, nonatomic) id<HardwareInfo> hardware;
@end