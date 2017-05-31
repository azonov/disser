//
// Created by Yaroslav Vorontsov on 21.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Coordinates.h"

@class MEMapBundle;
@protocol MEPositioningAlgorithm;
@protocol MELocationFilter;

extern const struct MENavigationNotificationKeys {
    __unsafe_unretained NSString *const locationDisabledNotification;
    __unsafe_unretained NSString *const locationUpdatedNotification;
} MENavigationNotificationKeys;

extern const struct MENavigationNotificationUserInfoKeys {
    __unsafe_unretained NSString *const locationKey;
    __unsafe_unretained NSString *const pivotBeaconsKey;
} MENavigationNotificationUserInfoKeys;

@interface MENavigationManager : NSObject
@property (strong, nonatomic) id<MEPositioningAlgorithm> trilaterationAlgorithm;
@property (assign, nonatomic, readonly) Point3D currentLocation;
- (void)startTrackingOnMap:(MEMapBundle *)mapBundle;
- (void)stopTrackingOnMap:(MEMapBundle *)mapBundle;
@end