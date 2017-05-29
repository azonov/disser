//
// Created by Yaroslav Vorontsov on 27.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <MapEngine/MapEngine.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "MEGaussianTrilateration.h"
#import "CLBeacon+Additions.h"
#import "MEProbabilisticHeight.h"
#import "MEConstants.h"
#import "MEBeaconRSSIFilter.h"
#import "MEBeaconRangeFilter.h"


static CGFloat const kMagnitudeTolerance = 0.01f;
static NSUInteger const kMaxIterationCount = 100;

@interface MEGaussianTrilateration ()
@property (strong, nonatomic) MEProbabilisticHeight *probabilisticHeight;
@property (strong, nonatomic) MEBeaconRSSIFilter *rssiFilter;
@property (assign, nonatomic) BOOL hasInitialLocation;
@end

@implementation MEGaussianTrilateration
@synthesize currentLocation;

#pragma mark - Initialization

- (instancetype)init
{
    if ((self = [super init])) {
        self.probabilisticHeight = [MEProbabilisticHeight new];
        self.rssiFilter = [[MEBeaconRSSIFilter alloc] initWithNextFilter:[MEBeaconRangeFilter new]];
        self.hasInitialLocation = NO;
    }
    return self;
}

#pragma mark - Protocol implementation

- (MEMapBundle *)mapBundle
{
    return self.probabilisticHeight.mapBundle;
}

- (void)setMapBundle:(MEMapBundle *)mapBundle
{
    self.probabilisticHeight.mapBundle = mapBundle;
}

// Algorithm based on Dmitry Garshin's ideas.
// Taken from Java implementation here: http://ideone.com/YaKyzF

- (Point3D)locationBasedOnBeacons:(NSDictionary *)beacons
{
    NSParameterAssert(beacons != nil);
    if (!self.hasInitialLocation) {
        // Initial value is needed
        Point3D location = Point3DMake(0, 0, 0);
        for (CLBeacon *beacon in beacons.allKeys) {
            MEMapBeacon *mapBeacon = beacons[beacon];
            Point3D point = mapBeacon.coordinate;
            Vector3DAdd(&location, point);
        }
        Vector3DMultiplyByScalar(&location, 1.0f / beacons.count);
        self.currentLocation = location;
        self.hasInitialLocation = YES;
    } else {
        for (NSUInteger i = 0; i < kMaxIterationCount; ++i) {
            Vector3D correction = Vector3DMake(0, 0, 0);
            for (CLBeacon *beacon in beacons.allKeys) {
                id<MECoordinateModifier> mapBeacon = beacons[beacon];
                // CGFloat deviation = [self.mapBundle pixelsFromCentimeters:0.5f * distance];
                Vector3D vector = [mapBeacon affectionVectorForPosition:self.currentLocation
                                                               distance:beacon.distance
                                                              deviation:(beacon.accuracy * 100)];
                // Reduce beacon's affection based on its generation
                Vector3DMultiplyByScalar(&vector, beacon.affectionCorrection);
                Vector3DAdd(&correction, vector);
            }
            // Adding height correction
            Vector3D vector = [self.probabilisticHeight affectionVectorForPosition:self.currentLocation
                                                                          distance:0
                                                                         deviation:0];
            Vector3DAdd(&correction, vector);
            // Checking if it's time to stop
            double correctionMagnitude = Vector3DLength(correction);
            if (correctionMagnitude < kMagnitudeTolerance) {
                DDLogDebug(@"Reached magnitude less than 0.01, stopping...");
                break;
            }
            // this is trick to achieve convergency and avoid periodic oscillations
            // FIXME: results should be filtered (i.e. - Kalman or exp window)
            // float scaleCoefficient = (i % 10) / 10.0f;
            // MEVector3DMakeMultiply(&correction, scaleCoefficient);
            Vector3DAdd(&self->currentLocation, correction);
        }
    }
    return self.currentLocation;
}

- (NSArray *)pivotBeaconsFromBeacons:(NSArray *)beacons
{
    return [self.rssiFilter processedBeaconsFromBeacons:beacons];
}


@end