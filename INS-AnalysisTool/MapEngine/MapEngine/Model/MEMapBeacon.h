//
// Created by Yaroslav Vorontsov on 20.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Coordinates.h"
#import "MECoordinateModifier.h"

@class MEMapBundle;

@interface MEMapBeacon : NSObject <MECoordinateModifier>
// Parent bundle for the beacon
@property (weak, nonatomic, readonly) MEMapBundle *mapBundle;
// Beacon's minor number
@property (assign, nonatomic) NSInteger minor;
// X coordinate on a hi-res map
@property (assign, nonatomic) NSInteger x;
// Y coordinate on a hi-res map
@property (assign, nonatomic) NSInteger y;
// Height of a beacon measured in centimeters
@property (assign, nonatomic) NSInteger h;
// Coordinate calculated based on x, y and scaleFactor
@property (assign, nonatomic, readonly) Point3D coordinate;
// Designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dict mapBundle:(MEMapBundle *)mapBundle;
@end