//
// Created by Yaroslav Vorontsov on 28.08.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MEBeacon : NSProxy
+ (instancetype)beaconWithBeacon:(CLBeacon *)beacon adjustment:(double)adjustment;
@end