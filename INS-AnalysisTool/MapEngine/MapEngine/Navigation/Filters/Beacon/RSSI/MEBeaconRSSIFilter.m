//
// Created by Yaroslav Vorontsov on 28.08.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

@import CocoaLumberjack;
#import "MEBeaconRSSIFilter.h"
#import "MEConstants.h"
#import "MEBeacon.h"

static double const kFirstGenAffectionAdjustment = 0.7;
static double const kSecondGenAffectionAdjustment = 0.4;

@interface MEBeaconRSSIFilter()
@property (strong, nonatomic, readonly) NSMutableSet *firstGeneration;
@property (strong, nonatomic, readonly) NSMutableSet *secondGeneration;
@property (strong, nonatomic, readonly) NSMutableDictionary *beaconMap;
@end

@implementation MEBeaconRSSIFilter
@synthesize nextFilter = _nextFilter;

#pragma mark - Initialization

- (instancetype)init
{
    if ((self = [super init])) {
        _beaconMap = [NSMutableDictionary dictionary];
        _firstGeneration = [NSMutableSet set];
        _secondGeneration = [NSMutableSet set];
    }
    return self;
}

- (instancetype)initWithNextFilter:(id<MEBeaconFilter>)theNextFilter
{
    if ((self = [self init])) {
        _nextFilter = theNextFilter;
    }
    return self;
}

#pragma mark - Utility methods

- (NSPredicate *)validStatusPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(CLBeacon * beacon, NSDictionary *bindings) {
        return beacon.proximity != CLProximityUnknown;
    }];
}

#pragma mark - Actual filter implementation

/**
 * Beacon processing works in the following way
 *
 * 1. There are 2 generations of invalid beacons. Beacon is put into 1st generation in case it is presented neither in
 *  1st nor in 2nd generation. Beacon is put into 2nd generation in case it was in the 1st generation and is marked as
 *  invalid by system again.
 * 2. Beacons which became invalid more than 2 times become untrusted and are removed completely from the filter
 * 3. In case beacon appears in field of vision again (its proximity is known), it's removed from all generations
 * 4. 1st gen beacons have affection level lower to last existing value, 2nd gen beacons - even lower.
 * 5. In case there's no RSSI saved previously, beacon is invalid, too
 *
 */
- (NSArray *)processedBeaconsFromBeacons:(NSArray *)beacons
{
    NSSet *activeBeacons = [NSSet setWithArray:[beacons filteredArrayUsingPredicate:self.validStatusPredicate]];
    NSMutableArray *validBeacons = [NSMutableArray arrayWithCapacity:beacons.count];
    if (activeBeacons.count > 0) {
        // We're processing all beacons
        for (CLBeacon *beacon in beacons) {
            // First of all, check if the beacon is active. If it's inactive - check if beacon-to-RSSI map
            // contains any valid RSSI value. If no, beacon is not taken into account
            if ([activeBeacons containsObject:beacon]) {
                // Save previous RSSI value and mark beacon as valid
                self.beaconMap[beacon.minor] = [beacon copy];
                [self.firstGeneration removeObject:beacon.minor];
                [self.secondGeneration removeObject:beacon.minor];
                [validBeacons addObject:beacon];
            } else if (self.beaconMap[beacon.minor] != nil) {
                // Try to find the beacon in 1st generation.
                // If it's not found, search it among 2nd generation
                if ([self.firstGeneration containsObject:beacon.minor]) {
                    // Move it into 2nd generation and create a proxy object with lowered affection
                    DDLogDebug(@"Moving beacon %@ to 2nd generation", beacon);
                    [self.firstGeneration removeObject:beacon.minor];
                    [self.secondGeneration addObject:beacon.minor];
                    MEBeacon *proxy = [MEBeacon beaconWithBeacon:self.beaconMap[beacon.minor]
                                                      adjustment:kSecondGenAffectionAdjustment];
                    [validBeacons addObject:proxy];
                } else if ([self.secondGeneration containsObject:beacon.minor]) {
                    // Beacon is not trusted anymore - remove it from both generations and RSSI map
                    DDLogDebug(@"Beacon %@ is not trusted anymore", beacon);
                    [self.secondGeneration removeObject:beacon.minor];
                    [self.beaconMap removeObjectForKey:beacon.minor];
                } else {
                    // Beacon is not found neither in first nor in second generation - add it as 1st gen beacon
                    // Create a proxy with lowered RSSI
                    DDLogDebug(@"New 1st generation beacon %@", beacon);
                    [self.firstGeneration addObject:beacon.minor];
                    MEBeacon *proxy = [MEBeacon beaconWithBeacon:self.beaconMap[beacon.minor]
                                                      adjustment:kFirstGenAffectionAdjustment];
                    [validBeacons addObject:proxy];
                }
            } else {
                DDLogDebug(@"Beacon %@ haven't been in valid state", beacon);
            }
        }
    } else {
        DDLogWarn(@"No beacons with unknown proximity detected");
    }
    return self.nextFilter ? [self.nextFilter processedBeaconsFromBeacons:validBeacons] : [validBeacons copy];
}

@end