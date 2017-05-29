//
// Created by Yaroslav Vorontsov on 21.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import CoreLocation;
@import CoreMotion;
@import CocoaLumberjack;


#import "WCSensorFusion.h"
#import "WCCSVDataGrabber.h"
#import "ILConstants.h"
#import "VectorUtils.h"


const struct WCSensorType WCSensorType = {
        .Accelerometer = @"Accelerometer",
        .Attitude = @"Attitude",
        .Compass = @"Compass",
        .DeviceAcceleration = @"DeviceAcceleration",
        .DeviceAccelerationStabilized = @"DeviceAccelerationStabilized",
        .GPS = @"GPS",
        .Gravity = @"Gravity",
        .GravityStabilized = @"GravityStabilized",
        .Gyroscope = @"Gyroscope",
        .MagneticField = @"MagneticField",
        .MagneticFieldStabilized = @"MagneticFieldStabilized",
        .Magnetometer = @"Magnetometer",
        .Motion = @"Motion",
        .Rotation = @"Rotation"
};

const struct WCSensorFusionNotifications WCSensorFusionNotifications = {
        .measurementCompleted = @"MeasurementCompleted"
};


#pragma mark - Additional declarations

@interface WCSensorFusion() <CLLocationManagerDelegate>
@property (strong, nonatomic, readonly) id<WCCSVDataGrabber> dataGrabber;
@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@property (strong, nonatomic, readonly) CMMotionManager *motionManager;
@property (strong, nonatomic, readonly) NSOperationQueue *handlerQueue;
@property (strong, nonatomic, readonly) NSTimer *timer;
@end


@implementation WCSensorFusion
{
    CLLocationManager *_locationManager;
    CMMotionManager *_motionManager;
    NSOperationQueue *_handlerQueue;
    NSTimer *_timer;
}

#pragma mark - Initializers

- (instancetype)initWithDataGrabber:(id<WCCSVDataGrabber>)dataGrabber
{
    if ((self = [super init])) {
        _dataGrabber = dataGrabber;
    }
    return self;
}

#pragma mark - Overridden getters/setters

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [CLLocationManager new];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

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

- (NSOperationQueue *)handlerQueue
{
    if (!_handlerQueue) {
        _handlerQueue = [NSOperationQueue new];
        _handlerQueue.maxConcurrentOperationCount = 2 * [NSProcessInfo processInfo].processorCount;
    }
    return _handlerQueue;
}

- (NSTimer *)timer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(timerFired:)
                                                userInfo:nil
                                                 repeats:YES];
    }
    return _timer;
}

#pragma mark - Logging methods

- (void)writeValues:(Vector3D)vector forSensor:(NSString *)sensor
{
    NSNumber *timestamp = @([NSDate date].timeIntervalSince1970);
    [_dataGrabber writeValues:@[
            timestamp.stringValue,
            sensor,
            @(vector.x),
            @(vector.y),
            @(vector.z)
    ]];
}

#pragma mark - Timer handler

- (void)timerFired:(NSTimer *)timer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WCSensorFusionNotifications.measurementCompleted
                                                        object:self];
}

#pragma mark - WCSensorFusion - implementation of protocol

- (void)startGatheringSensorData
{
    // Starting the queue
    self.handlerQueue.suspended = NO;
    // Starting location manager updates
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
    // Starting motion manager updates
    typeof(self) __weak that = self;
    [self.motionManager startAccelerometerUpdatesToQueue:self.handlerQueue
                                             withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                                 if (error != nil) {
                                                     DDLogWarn(@"Failed to receive accelerometer data due to an error: %@ (%@)", error.localizedDescription, error);
                                                 } else {
                                                     [that writeValues:FromAccelerometerData(accelerometerData) forSensor:WCSensorType.Accelerometer];
                                                 }
                                             }];
    [self.motionManager startGyroUpdatesToQueue:self.handlerQueue
                                    withHandler:^(CMGyroData *gyroData, NSError *error) {
                                        if (error != nil) {
                                            DDLogWarn(@"Failed to receive gyroscope data due to an error: %@ (%@)", error.localizedDescription, error);
                                        } else {
                                            [that writeValues:FromGyroscopeData(gyroData) forSensor:WCSensorType.Gyroscope];
                                        }
                                    }];
    [self.motionManager startMagnetometerUpdatesToQueue:self.handlerQueue
                                            withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
                                                if (error != nil) {
                                                    DDLogWarn(@"Failed to receive magnetometer data due to an error: %@ (%@)", error.localizedDescription, error);
                                                } else {
                                                    [that writeValues:FromMagnetometerData(magnetometerData) forSensor:WCSensorType.Magnetometer];
                                                }
                                            }];
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical
                                                            toQueue:self.handlerQueue
                                                        withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                            if (error != nil) {
                                                                DDLogWarn(@"Failed to receive accelerometer data due to an error: %@ (%@)", error.localizedDescription, error);
                                                            } else {
                                                                typeof(that) ref = that;
                                                                [ref writeValues:AccelerationFromMotion(motion) forSensor:WCSensorType.DeviceAcceleration];
                                                                [ref writeValues:StabilizedAccelerationFromMotion(motion) forSensor:WCSensorType.DeviceAccelerationStabilized];
                                                                [ref writeValues:GravityFromMotion(motion) forSensor:WCSensorType.Gravity];
                                                                [ref writeValues:StabilizedGravityFromMotion(motion) forSensor:WCSensorType.GravityStabilized];
                                                                [ref writeValues:MagneticFromMotion(motion) forSensor:WCSensorType.MagneticField];
                                                                [ref writeValues:StabilizedMagneticFromMotion(motion) forSensor:WCSensorType.MagneticFieldStabilized];
                                                                [ref writeValues:RotationFromMotion(motion) forSensor:WCSensorType.Rotation];
                                                                [ref writeValues:FromAttitude(motion.attitude) forSensor:WCSensorType.Attitude];
                                                            }
                                                        }];
    // Starting timer
    [self.timer fire];
}

- (void)stopGatheringSensorData
{
    // Stopping location manager
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
    // Stopping motion manager
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopGyroUpdates];
    [self.motionManager stopMagnetometerUpdates];
    [self.motionManager stopDeviceMotionUpdates];
    // Cancelling the rest of operations in operation queue
    [self.handlerQueue cancelAllOperations];
    self.handlerQueue.suspended = YES;
    // Timer invalidation
    [self.timer invalidate];
    _timer = nil;
}

#pragma mark - CLLocationManagerDelegate implementation - Access

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    return YES;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    DDLogInfo(@"Location manager's state has changed to %d", status);
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            [manager requestAlwaysAuthorization];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            DDLogDebug(@"Location services are already authorized for this app, continuing...");
            break;
        default:
            DDLogWarn(@"Unsuitable response received from location services. Go to Settings to authorize");
            break;
    }
}

#pragma mark - CLLocationManagerDelegate implementation - Heading

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    [self writeValues:FromHeading(newHeading) forSensor:WCSensorType.Compass];
}

#pragma mark - CLLocationManagerDelegate implementation - Location

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [self writeValues:FromLocation(locations.lastObject) forSensor:WCSensorType.GPS];
}

#pragma mark - CLLocationManagerDelegate implementation - Error handling

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DDLogWarn(@"Location manager failed with an error: %@ (%@)", error.localizedDescription, error);
}


@end