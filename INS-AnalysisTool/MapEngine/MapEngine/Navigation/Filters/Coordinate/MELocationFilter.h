//
// Created by Yaroslav Vorontsov on 27.08.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Coordinates.h"

@protocol MELocationFilter <NSObject>
@required
@property (strong, nonatomic) id<MELocationFilter> nextFilter;
- (void)startWithInitialLocation:(Point3D)location;
- (Vector3D)predictedValueForLocation:(Point3D)location;
@optional
- (id)initWithNextFilter:(id<MELocationFilter>)nextFilter;
@end