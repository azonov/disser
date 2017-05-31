//
// Created by Yaroslav Vorontsov on 17.10.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "Coordinates.h"
#import "MEMapBundle.h"
#import "MENavigationDataSource.h"

extern const struct MEMotionMeasurementType {
    __unsafe_unretained NSString *acceleration;
    __unsafe_unretained NSString *magnetometer;
    __unsafe_unretained NSString *motion;
    __unsafe_unretained NSString *gyroscope;
} MEMotionMeasurementType;


@interface MEMotionDataSource : NSObject <MENavigationDataSource>
@end