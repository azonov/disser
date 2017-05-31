//
// Created by Yaroslav Vorontsov on 26.10.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MESettingsManager : NSObject
@property (assign, nonatomic, readonly) double averageStepLength; // measured in meters
@property (assign, nonatomic) double positionAccuracy; // measured in meters;
@property (assign, nonatomic) double traceDissipationRate; // how slow the validity of beacon signal fades
@property (assign, nonatomic) double accuracyChangeRate; // how fast accuracy is updated; belongs to [0..1] interval
@end