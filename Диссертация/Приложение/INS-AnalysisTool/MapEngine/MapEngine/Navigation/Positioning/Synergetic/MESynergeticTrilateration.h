//
// Created by Yaroslav Vorontsov on 17.10.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEPositioningAlgorithm.h"

/**
 * Implements a synergetic approach based on both Gaussian distribution and affection vectors and motion data
 * Each beacon attracts/distracts the location's point using some force. Beacons are used as a source of correction.
 * Coordinates are calculated based on the
 *
 */
@interface MESynergeticTrilateration : NSObject <MEPositioningAlgorithm>
@end