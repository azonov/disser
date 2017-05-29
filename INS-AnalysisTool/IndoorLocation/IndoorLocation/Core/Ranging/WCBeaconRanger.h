//
// Created by Yaroslav Vorontsov on 30.05.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import CoreLocation;

@protocol WCCSVDataGrabber;


extern const struct WCBeaconRangerNotifications {
    __unsafe_unretained NSString *const beaconsRanged;
} WCBeaconRangerNotifications;

@protocol WCBeaconRanger <NSObject>
- (void)startTrackingRegion:(CLBeaconRegion *)region;
- (void)stopTrackingRegion:(CLBeaconRegion *)region;
@end

@interface WCBeaconRanger : NSObject <WCBeaconRanger, CLLocationManagerDelegate>
- (instancetype)initWithCSVGrabber:(id<WCCSVDataGrabber>)grabber;
@end