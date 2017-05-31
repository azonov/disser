//
// Created by Yaroslav Vorontsov on 21.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <MapEngine/MapEngine.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "MEConstants.h"
#import "MEBeaconSignalDataSource.h"
#import "MEMotionDataSource.h"
#import "OrientationProcessor.h"

const struct MENavigationNotificationKeys MENavigationNotificationKeys = {
        .locationDisabledNotification = @"MENavigationManager.locationDisabledNotification",
        .locationUpdatedNotification = @"MENavigationManager.locationUpdatedNotification",
};

const struct MENavigationNotificationUserInfoKeys MENavigationNotificationUserInfoKeys = {
        .locationKey = @"MELocationUserInfo.location",
        .pivotBeaconsKey = @"MELocationUserInfo.pivotBeacons"
};

@interface MENavigationManager()
@property (strong, nonatomic, readonly) NSNotificationCenter *notificationCenter;
@property (strong, nonatomic, readonly) NSArray<id<MENavigationDataSource>> *dataSources;
@property (strong, nonatomic, readonly) NSTimer *timer;
@property (strong, nonatomic) MEMapBundle *trackedMap;
@property (strong, nonatomic) NSArray *pivotBeacons;
@property (assign, nonatomic) Vector3D predictedLocation;
@end

@implementation MENavigationManager
{
    NSDate *_initialTimestamp;
    NSArray *_dataSources;
    IndoorNavigation::OrientationProcessor *_processor;
}

#pragma mark - Initialization and memory management

- (instancetype)init
{
    if ((self = [super init])) {
        _notificationCenter = [NSNotificationCenter defaultCenter];
        _processor = new IndoorNavigation::OrientationProcessor(Point2DMake(17, -16), 2, -62);
    }
    return self;
}

- (void)dealloc
{
    [_timer invalidate];
    delete _processor;
}

#pragma mark - Getters and setters

- (Point3D)currentLocation
{
    return self.predictedLocation;
}

- (NSArray *)dataSources
{
    if (!_dataSources) {
        typeof(self) __weak that = self;
        _dataSources = @[
                [[MEBeaconSignalDataSource new] addListener:^(NSString *identifier, NSValue *value) {
                    [that processBeacons:value];
                }] ,
                [[MEMotionDataSource new] addListener:^(NSString *identifier, NSValue *value) {
                    if ([identifier hasSuffix:MEMotionMeasurementType.acceleration]) {
                        [that processAcceleration:value];
                    } else if ([identifier hasSuffix:MEMotionMeasurementType.magnetometer]) {
                        [that processMagneticMeasurement:value];
                    } else if ([identifier hasSuffix:MEMotionMeasurementType.gyroscope]) {
                        [that processGyroMeasurement:value];
                    }
                }],
        ];
    }
    return _dataSources;
}

#pragma mark - Helper methods

- (NSTimeInterval)currentTimeDelta
{
    if (!_initialTimestamp) {
        _initialTimestamp = [NSDate date];
    }
    return [[NSDate date] timeIntervalSinceDate:_initialTimestamp];
}

- (NSArray *)mapBeaconsForBeacons:(NSArray<CLBeacon *> *)beacons
{
    // Preparing an array of pivot beacon identifiers
    NSMutableArray *pivotBeacons = [NSMutableArray arrayWithCapacity:beacons.count];
    for (CLBeacon *beacon in beacons) {
        [pivotBeacons addObject:beacon.minor];
    }
    return pivotBeacons;
}

#pragma mark - Map tracking management

- (void)startTrackingOnMap:(MEMapBundle *)mapBundle
{
    if (self.trackedMap != nil) {
        [self stopTrackingOnMap:self.trackedMap];
    }
    if (!self.trackedMap) {
        // Save map to the list of tracked maps
        self.trackedMap = mapBundle;
        [self.dataSources makeObjectsPerformSelector:@selector(startTrackingOnMap:) withObject:mapBundle];
        // Register beacons
        for (MEMapBeacon *beacon in mapBundle.beacons) {
            double x = [mapBundle centimetersFromPixels:beacon.x] / 100.0;
            // Because of right
            double y = - [mapBundle centimetersFromPixels:beacon.y] / 100.0;
            _processor->AddBeaconInfo((int)beacon.minor, Vector2DMake(x, y));
        }
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                  target:self
                                                selector:@selector(postLocationUpdates)
                                                userInfo:nil
                                                 repeats:YES];
    }
}

- (void)stopTrackingOnMap:(MEMapBundle *)mapBundle
{
    if (self.trackedMap != nil) {
        // Remove map from the list of tracked maps
        [self.dataSources makeObjectsPerformSelector:@selector(stopTrackingOnMap:) withObject:mapBundle];
        self.trackedMap = nil;
        // Unregister beacons
        [_timer invalidate];
    }
}

#pragma mark - Working with engine

- (void)processAcceleration:(NSValue *)accValue
{
    Vector3D acc;
    [accValue getValue:&acc];
    TimeVector3D measurement = TimeVector3DMake(self.currentTimeDelta, acc.x, acc.y, acc.z);
    dispatch_async(dispatch_get_main_queue(), ^{
        _processor->NewAccelerationReadingPhone(measurement);
    });
}

- (void)processMagneticMeasurement:(NSValue *)magValue
{
    Vector3D mag;
    [magValue getValue:&mag];
    TimeVector3D measurement = TimeVector3DMake(self.currentTimeDelta, mag.x, mag.y, mag.z);
    dispatch_async(dispatch_get_main_queue(), ^{
        _processor->NewMagneticReadingPhone(measurement);
    });
}

- (void)processGyroMeasurement:(NSValue *)gyroValue
{
    Vector3D gyro;
    [gyroValue getValue:&gyro];
    TimeVector3D measurement = TimeVector3DMake(self.currentTimeDelta, gyro.x, gyro.y, gyro.z);
    dispatch_async(dispatch_get_main_queue(), ^{
        _processor->NewGyroReading(measurement);
    });
}

- (void)processBeacons:(NSValue *)beaconMap
{
    // Extracting the values
    NSDictionary *dict = beaconMap.nonretainedObjectValue;
    CLBeaconRegion *region = dict.allKeys.firstObject;
    NSArray<CLBeacon *> *rangedBeacons = dict[region];
    for (CLBeacon *beacon in rangedBeacons) {
        auto distance = _processor->GetDistanceFromRssi(beacon.rssi);
        _processor->NewBeaconSignalArrived(self.currentTimeDelta, beacon.minor.intValue, distance);
    }
    // Saving pivot beacons
    self.pivotBeacons = [self mapBeaconsForBeacons:rangedBeacons];
}

- (void)postLocationUpdates
{
//    Vector3D location = [self.trilaterationAlgorithm locationBasedOnBeacons:beaconMapping];
//    // Checking whether the location is inside map bounds
//    CGPoint scaledLocation = CGPointMake((CGFloat) (location.x / mapBundle.maxScale), (CGFloat) (location.y / mapBundle.maxScale));
//    if (CGRectContainsPoint(mapBundle.imageBounds, scaledLocation)) {
//        // Checking if location has already been predicted
//        if (Vector3DLength(self.predictedLocation) < 10e-4) {
//            self.predictedLocation = location;
//        }
//        // Using previously predicted location
//        Vector3D avgLocation = Vector3DSum(self.predictedLocation, location);
//        Vector3DMultiplyByScalar(&avgLocation, 0.5f);
//        self.trilaterationAlgorithm.currentLocation = avgLocation;
//        // Predicting next location
//        self.predictedLocation = location;
//        // self.predictedLocation = [self.filter predictedValueForLocation:location];
//        DDLogDebug(@"Location calculated (%.4f, %.4f)", self.currentLocation.x, self.currentLocation.y);

    // Posting a notification
//    if (self.pivotBeacons.count > 0) {
        Point2D position = _processor->GetPosition(); // Coordinates are in meters
        // Convert into specific units
        double pxX = [self.trackedMap pixelsFromCentimeters:position.x * 100];
        double pxY = -[self.trackedMap pixelsFromCentimeters:position.y * 100];
        self.predictedLocation = Vector3DMake(pxX, pxY, 0);

        DDLogDebug(@"Received a location update: %.4f, %.4f", self.predictedLocation.x, self.predictedLocation.y);
        Vector3D location = self.predictedLocation;
        NSDictionary *userInfo = @{
                MENavigationNotificationUserInfoKeys.pivotBeaconsKey : self.pivotBeacons ?: @[],
                MENavigationNotificationUserInfoKeys.locationKey: [NSValue valueWithPointer:&location]
        };
        [self.notificationCenter postNotificationName:MENavigationNotificationKeys.locationUpdatedNotification
                                               object:self
                                             userInfo:userInfo];
//    }
}

@end
