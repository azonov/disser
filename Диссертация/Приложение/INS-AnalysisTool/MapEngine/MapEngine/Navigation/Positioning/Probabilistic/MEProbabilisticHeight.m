//
// Created by Yaroslav Vorontsov on 27.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <MapEngine/MapEngine.h>
#import "MEProbabilisticHeight.h"

static const CGFloat kMedianHeight = 115;
static const CGFloat kStdDeviation = 45;

@implementation MEProbabilisticHeight

- (Vector3D)affectionVectorForPosition:(Point3D)position distance:(double)distance deviation:(double)deviation
{
    double avgHeight = [self.mapBundle pixelsFromCentimeters:kMedianHeight];
    deviation = [self.mapBundle pixelsFromCentimeters:kStdDeviation];
    return Vector3DMake(0, 0, GetAffection(position.z, avgHeight, deviation));
}

@end