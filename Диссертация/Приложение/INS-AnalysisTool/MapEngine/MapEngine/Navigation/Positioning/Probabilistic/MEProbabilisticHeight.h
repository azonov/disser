//
// Created by Yaroslav Vorontsov on 27.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MECoordinateModifier.h"

@class MEMapBundle;

/**
 * A probabilistic model for the height of the telephone over the floor level
 */
@interface MEProbabilisticHeight : NSObject <MECoordinateModifier>
@property (weak, nonatomic) MEMapBundle *mapBundle;
@end