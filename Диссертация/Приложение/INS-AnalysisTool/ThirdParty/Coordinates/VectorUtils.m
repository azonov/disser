//
// Created by Yaroslav Vorontsov on 22.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "VectorUtils.h"

#pragma mark - Transformation utils

inline Quaternion FromCMQuaternion(CMQuaternion q) {
    return (Quaternion) {
            .x = q.x,
            .y = q.y,
            .z = q.z,
            .w = q.w
    };
}

#pragma mark - Vectors

inline Vector3D FromAccelerometerData(CMAccelerometerData *data) {
    return (Vector3D) {
            .x = data.acceleration.x,
            .y = data.acceleration.y,
            .z = data.acceleration.z
    };
}

inline Vector3D FromAttitude(CMAttitude *attitude) {
    return (Vector3D) {
            .x = attitude.roll,
            .y = attitude.pitch,
            .z = attitude.yaw
    };
}

inline Vector3D FromMagnetometerData(CMMagnetometerData *data) {
    return (Vector3D) {
            .x = data.magneticField.x,
            .y = data.magneticField.y,
            .z = data.magneticField.z
    };
}

inline Vector3D FromGyroscopeData(CMGyroData *data) {
    return (Vector3D) {
            .x = data.rotationRate.x,
            .y = data.rotationRate.y,
            .z = data.rotationRate.z
    };
}

inline Vector3D FromLocation(CLLocation *location) {
    return (Vector3D) {
            .x = location.coordinate.latitude,
            .y = location.coordinate.longitude,
            .z = location.altitude
    };
}

inline Vector3D FromHeading(CLHeading *heading) {
    return (Vector3D) {
            .x = heading.x,
            .y = heading.y,
            .z = heading.z
    };
}

#pragma mark - Calculated values in world reference frame

inline Vector3D AccelerationFromMotion(CMDeviceMotion *motion) {
    return (Vector3D) {
            .x = motion.userAcceleration.x,
            .y = motion.userAcceleration.y,
            .z = motion.userAcceleration.z
    };
}

inline Vector3D GravityFromMotion(CMDeviceMotion *motion) {
    return (Vector3D) {
            .x = motion.gravity.x,
            .y = motion.gravity.y,
            .z = motion.gravity.z
    };
}

inline Vector3D RotationFromMotion(CMDeviceMotion *motion) {
    return (Vector3D) {
            .x = motion.rotationRate.x,
            .y = motion.rotationRate.y,
            .z = motion.rotationRate.z
    };
}

inline Vector3D MagneticFromMotion(CMDeviceMotion *motion) {
    return (Vector3D) {
            .x = motion.magneticField.field.x,
            .y = motion.magneticField.field.y,
            .z = motion.magneticField.field.z
    };
}

// ga = QgQ'

inline Vector3D StabilizedGravityFromMotion(CMDeviceMotion *motion) {
    Quaternion gravityQ = QuaternionFromVector3D(GravityFromMotion(motion));
    Quaternion attQ = FromCMQuaternion(motion.attitude.quaternion);
    return Vector3DFromQuaternion(QuaternionMultiply(QuaternionMultiply(attQ, gravityQ), QuaternionConjugate(attQ)));
}

inline Vector3D StabilizedAccelerationFromMotion(CMDeviceMotion *motion) {
    Quaternion accQ = QuaternionFromVector3D(AccelerationFromMotion(motion));
    Quaternion attQ = FromCMQuaternion(motion.attitude.quaternion);
    return Vector3DFromQuaternion(QuaternionMultiply(QuaternionMultiply(attQ, accQ), QuaternionConjugate(attQ)));
}

inline Vector3D StabilizedMagneticFromMotion(CMDeviceMotion *motion) {
    Quaternion magQ = QuaternionFromVector3D(MagneticFromMotion(motion));
    Quaternion attQ = FromCMQuaternion(motion.attitude.quaternion);
    return Vector3DFromQuaternion(QuaternionMultiply(QuaternionMultiply(attQ, magQ), QuaternionConjugate(attQ)));
}