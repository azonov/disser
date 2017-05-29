//
// Created by Yaroslav Vorontsov on 22.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#if defined __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "Coordinates.h"

#pragma mark - Quaternion transformations
extern Quaternion FromCMQuaternion(CMQuaternion q);

#pragma mark - Vectors
extern Vector3D FromAccelerometerData(CMAccelerometerData *data);
extern Vector3D FromAttitude(CMAttitude *attitude);
extern Vector3D FromGyroscopeData(CMGyroData *data);
extern Vector3D FromHeading(CLHeading *heading);
extern Vector3D FromLocation(CLLocation *location);
extern Vector3D FromMagnetometerData(CMMagnetometerData *data);

#pragma mark - Calculated values in world reference frame
extern Vector3D AccelerationFromMotion(CMDeviceMotion *motion);
extern Vector3D GravityFromMotion(CMDeviceMotion *motion);
extern Vector3D MagneticFromMotion(CMDeviceMotion *motion);
extern Vector3D RotationFromMotion(CMDeviceMotion *motion);
extern Vector3D StabilizedAccelerationFromMotion(CMDeviceMotion *motion);
extern Vector3D StabilizedGravityFromMotion(CMDeviceMotion *motion);
extern Vector3D StabilizedMagneticFromMotion(CMDeviceMotion *motion);

#if defined __cplusplus
};
#endif