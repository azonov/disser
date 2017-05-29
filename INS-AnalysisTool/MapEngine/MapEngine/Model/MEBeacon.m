//
// Created by Yaroslav Vorontsov on 28.08.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import "MEBeacon.h"

@interface MEBeacon()
@property (strong, nonatomic, readonly) CLBeacon *beacon;
@property (assign, nonatomic, readonly) double affectionCorrection;
@end

@implementation MEBeacon

+ (instancetype)beaconWithBeacon:(CLBeacon *)beacon adjustment:(double)adjustment
{
    return [[self alloc] initWithBeacon:beacon adjustment:adjustment];
}

- (instancetype)initWithBeacon:(CLBeacon *)beacon adjustment:(double)adjustment
{
    _beacon = beacon;
    _affectionCorrection = adjustment;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [self.beacon methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:self.beacon];
}

- (NSString *)description
{
    return self.beacon.description;
}


@end