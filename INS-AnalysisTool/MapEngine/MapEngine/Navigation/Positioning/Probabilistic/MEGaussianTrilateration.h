//
// Created by Yaroslav Vorontsov on 27.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapEngine/MapEngine.h>

/**
 * Implements a probabilistic approach based on Gaussian distribution and affection vectors.
 * Each beacon attracts/distracts the location's point using some force.
 */
@interface MEGaussianTrilateration : NSObject <MEPositioningAlgorithm>
@end