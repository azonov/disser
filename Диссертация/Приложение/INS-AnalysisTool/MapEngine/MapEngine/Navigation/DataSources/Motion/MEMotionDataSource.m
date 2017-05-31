//
// Created by Yaroslav Vorontsov on 17.10.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

#import "MEMotionDataSource.h"
#import "VectorUtils.h"
#import "MEConstants.h"

const struct MEMotionMeasurementType MEMotionMeasurementType = {
        .acceleration = @"Acceleration",
        .magnetometer = @"Magnetometer",
        .gyroscope = @"Gyroscope",
        .motion = @"Motion",
};

@interface MEMotionDataSource()
@property (strong, nonatomic, readonly) CMMotionManager *motionManager;
@property (strong, nonatomic, readonly) NSOperationQueue *delegateQueue;
@property (strong, nonatomic, readonly) NSMutableArray *listeners;
@property (strong, nonatomic) NSUUID *trackedRegionID;
@property (assign, nonatomic) BOOL running;
@end


@implementation MEMotionDataSource
{
    CMMotionManager *_motionManager;
    NSOperationQueue *_delegateQueue;
}

#pragma mark - Initializers

- (instancetype)init
{
    if ((self = [super init])) {
        _listeners = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    [_motionManager stopDeviceMotionUpdates];
    [_delegateQueue cancelAllOperations];
}

#pragma mark - Overridden properties

- (CMMotionManager *)motionManager
{
    if (!_motionManager) {
        _motionManager = [CMMotionManager new];
        _motionManager.showsDeviceMovementDisplay = YES;
        NSTimeInterval defaultInterval = 1 / 60.0;
        _motionManager.deviceMotionUpdateInterval = defaultInterval;
        _motionManager.accelerometerUpdateInterval = defaultInterval;
        _motionManager.gyroUpdateInterval = defaultInterval;
        _motionManager.magnetometerUpdateInterval = defaultInterval;
    }
    return _motionManager;
}

- (NSOperationQueue *)delegateQueue
{
    if (!_delegateQueue) {
        _delegateQueue = [NSOperationQueue new];
        _delegateQueue.maxConcurrentOperationCount = 2 * [NSProcessInfo processInfo].activeProcessorCount;
    }
    return _delegateQueue;
}

#pragma mark - Implementation of MENavigationDataSource

- (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (id<MENavigationDataSource>)addListener:(MENavigationDataSourceListenerBlock)block
{
    [self.listeners addObject:[block copy]];
    return self;
}

- (void)startTrackingOnMap:(MEMapBundle *)mapBundle
{
    if (!self.running) {
        self.running = YES;
        self.trackedRegionID = mapBundle.buildingUUID;
        typeof(self) __weak that = self;
        [self.motionManager startAccelerometerUpdatesToQueue:self.delegateQueue
                                                 withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                                     if (error != nil) {
                                                         DDLogWarn(@"Failed to process accelerometer update: %@", error);
                                                     } else {
                                                         [that processAcceleration:accelerometerData];
                                                     }
                                                 }];
        [self.motionManager startGyroUpdatesToQueue:self.delegateQueue
                                        withHandler:^(CMGyroData *gyroData, NSError *error) {
                                            if (error != nil) {
                                                DDLogWarn(@"Failed to process gyroscope update: %@", error);
                                            } else {
                                                [that processGyroMeasurement:gyroData];
                                            }
                                        }];
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical
                                                                toQueue:self.delegateQueue
                                                            withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                                if (error != nil) {
                                                                    DDLogWarn(@"Failed to process device motion: %@", error);
                                                                } else {
                                                                    [that processMagneticFieldFromMotion:motion];
                                                                }
                                                            }];
    }
}

- (void)stopTrackingOnMap:(MEMapBundle *)mapBundle
{
    if (self.running && [self.trackedRegionID isEqual:mapBundle.buildingUUID]) {
        self.running = NO;
        [self.motionManager stopDeviceMotionUpdates];
        self.trackedRegionID = nil;
    }
}

#pragma mark - Utility methods

- (void)notifyListenersOfEventID:(const NSString *)eventID value:(NSValue *)value
{
    NSParameterAssert(eventID != nil);
    NSString *identifier = [@[self.identifier, eventID] componentsJoinedByString:@"."];
    // Notify listeners
    for (MENavigationDataSourceListenerBlock listener in self.listeners) {
        listener(identifier, value);
    }
}

- (void)processAcceleration:(CMAccelerometerData *)data
{
    Vector3D acceleration = FromAccelerometerData(data);
    Vector3DMultiplyByScalar(&acceleration, -9.81); // Multiply by g=9.81 m/s2
    [self notifyListenersOfEventID:MEMotionMeasurementType.acceleration
                             value:[NSValue value:&acceleration withObjCType:@encode(Vector3D)]];
}

- (void)processMagneticFieldFromMotion:(CMDeviceMotion *)data
{
    Vector3D magnetic = MagneticFromMotion(data);
    [self notifyListenersOfEventID:MEMotionMeasurementType.magnetometer
                             value:[NSValue value:&magnetic withObjCType:@encode(Vector3D)]];
}

- (void)processGyroMeasurement:(CMGyroData *)data
{
    Vector3D gyro = FromGyroscopeData(data);
    [self notifyListenersOfEventID:MEMotionMeasurementType.gyroscope
                             value:[NSValue value:&gyro withObjCType:@encode(Vector3D)]];
}

@end