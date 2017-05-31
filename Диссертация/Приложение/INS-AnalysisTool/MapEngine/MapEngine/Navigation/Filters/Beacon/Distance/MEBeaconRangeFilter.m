//
// Created by Yaroslav Vorontsov on 28.08.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import "MEBeaconRangeFilter.h"
#import <CoreLocation/CoreLocation.h>
#import "CLBeacon+Additions.h"

//static CLLocationDistance const kDistanceTolerance = 500;
static CLLocationDistance const kAccuracyTolerance = 20.0;

@implementation MEBeaconRangeFilter
@synthesize nextFilter;

- (NSPredicate *)proximityPredicate
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(CLBeacon *beacon, NSDictionary *bindings) {
        return beacon.accuracy > 0 && beacon.accuracy < kAccuracyTolerance && beacon.proximity != CLProximityUnknown;
    }];
    return predicate;
}

- (NSArray *)processedBeaconsFromBeacons:(NSArray *)beacons
{
    NSArray *filteredBeacons = [beacons filteredArrayUsingPredicate:self.proximityPredicate];
    return self.nextFilter ? [self.nextFilter processedBeaconsFromBeacons:filteredBeacons] : filteredBeacons;
}

@end