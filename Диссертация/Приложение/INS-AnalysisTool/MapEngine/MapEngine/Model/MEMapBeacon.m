//
// Created by Yaroslav Vorontsov on 20.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <MapEngine/MapEngine.h>
#import "MEMapBeacon.h"

@implementation MEMapBeacon
{

}

#pragma mark - Initialization and memory management

- (instancetype)initWithDictionary:(NSDictionary *)dict mapBundle:(MEMapBundle *)mapBundle
{
    NSParameterAssert(mapBundle != nil);
    NSParameterAssert(dict != nil);
    if ((self = [super init])) {
        _mapBundle = mapBundle;
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

#pragma mark - Points

- (Point3D)coordinate
{
    return Point3DMake(self.x, self.y, [self.mapBundle pixelsFromCentimeters:self.h]);
}

#pragma mark - Coordinate calculations

- (Vector3D)affectionVectorForPosition:(Point3D)position distance:(double)distance deviation:(double)deviation
{
    Vector3D result = Vector3DDiff(position, self.coordinate);
    double factDistance = Vector3DLength(result);
    if (fabs(factDistance) < 10e-3) {
        return Vector3DMake(0, 0, 0);
    }
    double pxDistance = [self.mapBundle pixelsFromCentimeters:distance];
    double pxDeviation = [self.mapBundle pixelsFromCentimeters:deviation];
    double affection = GetAffection(factDistance, pxDistance, pxDeviation);
    Vector3DMultiplyByScalar(&result, affection / factDistance);
    return result;
}

@end