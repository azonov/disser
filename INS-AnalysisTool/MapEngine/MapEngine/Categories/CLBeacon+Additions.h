//
// Created by Yaroslav Vorontsov on 24.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CLBeacon (Additions)
@property (assign, nonatomic, readonly) CLLocationDistance distance;
@property (assign, nonatomic, readonly) double affectionCorrection;
@end