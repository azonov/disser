//
// Created by Yaroslav Vorontsov on 21.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Coordinates.h"

@class MEMapBundle;

/**
 * This protocol declares an interface for a positioning algorithm
 */
@protocol MEPositioningAlgorithm <NSObject>
// Current location calculated by the algorithm
@property (assign, nonatomic) Point3D currentLocation;
// Map bundle used for calculations;
@property (weak, nonatomic) MEMapBundle *mapBundle;
// This method allows to filter appropriate pivot beacons
- (NSArray *)pivotBeaconsFromBeacons:(NSArray *)beacons;
// This method takes CLBeacon->MEMapBeacon mapping to calculate current location
- (Point3D)locationBasedOnBeacons:(NSDictionary *)beacons;
@end