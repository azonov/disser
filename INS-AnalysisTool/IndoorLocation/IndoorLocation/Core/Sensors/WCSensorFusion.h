//
// Created by Yaroslav Vorontsov on 21.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;

@protocol WCCSVDataGrabber;

extern const struct WCSensorType {
    __unsafe_unretained NSString *const Accelerometer;
    __unsafe_unretained NSString *const Attitude;
    __unsafe_unretained NSString *const Compass;
    __unsafe_unretained NSString *const DeviceAcceleration;
    __unsafe_unretained NSString *const DeviceAccelerationStabilized;
    __unsafe_unretained NSString *const GPS;
    __unsafe_unretained NSString *const Gravity;
    __unsafe_unretained NSString *const GravityStabilized;
    __unsafe_unretained NSString *const Gyroscope;
    __unsafe_unretained NSString *const MagneticField;
    __unsafe_unretained NSString *const MagneticFieldStabilized;
    __unsafe_unretained NSString *const Magnetometer;
    __unsafe_unretained NSString *const Motion;
    __unsafe_unretained NSString *const Rotation;
} WCSensorType;

extern const struct WCSensorFusionNotifications {
    __unsafe_unretained NSString *const measurementCompleted;
} WCSensorFusionNotifications;


@protocol WCSensorFusion
- (void)startGatheringSensorData;
- (void)stopGatheringSensorData;
@end

@interface WCSensorFusion : NSObject <WCSensorFusion>
- (instancetype)initWithDataGrabber:(id<WCCSVDataGrabber>)dataGrabber;
@end