//
// Created by Yaroslav Vorontsov on 17.10.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "MESynergeticTrilateration.h"
#import "OrientationProcessor.h"
#import "MEBeaconRSSIFilter.h"
#import "MEBeaconRangeFilter.h"

@interface MESynergeticTrilateration()
@property (strong, nonatomic, readonly) MEBeaconRSSIFilter *rssiFilter;
@property (assign, nonatomic) BOOL hasInitialLocation;
@end

@implementation MESynergeticTrilateration
{
    IndoorNavigation::OrientationProcessor _processor;
}
@synthesize currentLocation, mapBundle;


- (instancetype)init
{
    if ((self = [super init])) {
        _rssiFilter = [[MEBeaconRSSIFilter alloc] initWithNextFilter:[MEBeaconRangeFilter new]];
        self.hasInitialLocation = NO;
    }

    return self;
}

- (NSArray *)pivotBeaconsFromBeacons:(NSArray *)beacons
{
    return [self.rssiFilter processedBeaconsFromBeacons:beacons];
}

- (Point3D)locationBasedOnBeacons:(NSDictionary *)beacons
{
    Point3D result;
    return result;
}


@end