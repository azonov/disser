//
// Created by Yaroslav Vorontsov on 27.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Coordinates.h"

@protocol MECoordinateModifier <NSObject>
- (Vector3D)affectionVectorForPosition:(Point3D)position distance:(double)distance deviation:(double)deviation;
@end

extern double cdf(double x, double mu, double sigma);
extern double GetAffection(double factDistance, double estDistance, double deviation);
