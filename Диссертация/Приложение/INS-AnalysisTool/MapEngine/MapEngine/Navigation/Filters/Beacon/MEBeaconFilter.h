//
// Created by Yaroslav Vorontsov on 28.08.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MEBeaconFilter <NSObject>
@property (strong, nonatomic) id<MEBeaconFilter> nextFilter;
- (NSArray *)processedBeaconsFromBeacons:(NSArray *)beacons;
@optional
- (id)initWithNextFilter:(id<MEBeaconFilter>)nextFilter;
@end