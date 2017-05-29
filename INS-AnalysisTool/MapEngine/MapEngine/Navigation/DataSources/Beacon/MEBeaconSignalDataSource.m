//
// Created by Yaroslav Vorontsov on 17.10.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <MapEngine/MapEngine.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "MEConstants.h"
#import "MEBeaconSignalDataSource.h"
#import "MEBeaconFilter.h"
#import "MEBeaconRangeFilter.h"
#import "MEBeaconRSSIFilter.h"


@interface MEBeaconSignalDataSource() <CLLocationManagerDelegate>
@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@property (strong, nonatomic, readonly) NSNotificationCenter *notificationCenter;
@property (strong, nonatomic, readonly) NSMutableArray *listeners;
@property (strong, nonatomic, readonly) id<MEBeaconFilter> filter;
@end

@implementation MEBeaconSignalDataSource
{
    CLLocationManager *_locationManager;
}

#pragma mark - Initialization and memory management

- (instancetype)init
{
    if ((self = [super init])) {
        _notificationCenter = [NSNotificationCenter defaultCenter];
        _listeners = [NSMutableArray array];
        _filter = [[MEBeaconRSSIFilter alloc] initWithNextFilter:[MEBeaconRangeFilter new]];
    }
    return self;
}

#pragma mark - Getters and setters

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

#pragma mark - Helpers

- (CLBeaconRegion *)regionForMap:(MEMapBundle *)mapBundle
{
    return [[CLBeaconRegion alloc] initWithProximityUUID:mapBundle.buildingUUID
                                                   major:mapBundle.major
                                              identifier:mapBundle.name];
}

#pragma mark - Navigation data source - implementation

- (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (id<MENavigationDataSource>)addListener:(MENavigationDataSourceListenerBlock)block
{
    [self.listeners addObject:[block copy]];
    return self;
}

- (void)startTrackingOnMap:(MEMapBundle *)mapBundle
{
    CLBeaconRegion *region = [self regionForMap:mapBundle];
    if (![self.locationManager.monitoredRegions containsObject:region]) {
        [self.locationManager startMonitoringForRegion:region];
    }
}

- (void)stopTrackingOnMap:(MEMapBundle *)mapBundle
{
    CLBeaconRegion *region = [self regionForMap:mapBundle];
    if ([self.locationManager.monitoredRegions containsObject:region]) {
        [self.locationManager stopMonitoringForRegion:region];
    }
}

#pragma mark - CLLocationManagerDelegate (Authentication) implementation

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self checkAuthorizationStatus:status];
}

- (void)checkAuthorizationStatus:(CLAuthorizationStatus)status
{
    DDLogInfo(@"Authorization status has been set to %zd", status);
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            // Request authorization for location usage
            [self.locationManager requestAlwaysAuthorization];
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways: {
            // Do nothing, we're already here. Just call monitoring update for any region
            CLRegion *anyRegion = self.locationManager.monitoredRegions.anyObject;
            if (anyRegion != nil) {
                [self.locationManager requestStateForRegion:anyRegion];
            }
            break;
        }
        default: {
            DDLogWarn(@"Location services are disabled!");
            [self.notificationCenter postNotificationName:MENavigationNotificationKeys.locationDisabledNotification
                                                   object:self];
            break;
        }
    }
}

#pragma mark - CLLocationManagerDelegate (Region monitoring) implementation

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self processRegion:(CLBeaconRegion *)region forState:state];
    }
}

- (void)processRegion:(CLBeaconRegion *)region forState:(CLRegionState)state
{
    DDLogDebug(@"Determined state %zd for region: %@", state, region.identifier);
    switch (state) {
        case CLRegionStateInside: {
            [self.locationManager startRangingBeaconsInRegion:region];
            break;
        }
        case CLRegionStateOutside: {
            [self.locationManager stopRangingBeaconsInRegion:region];
            break;
        }
        default: {
            DDLogWarn(@"Unknown region %@ state! (%zd)", region.identifier, state);
            break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *) region;
        DDLogDebug(@"Entered building %@, floor %i", beaconRegion.proximityUUID.UUIDString, beaconRegion.major.unsignedShortValue);
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *) region;
        DDLogDebug(@"Left building %@, floor %i", beaconRegion.proximityUUID.UUIDString, beaconRegion.major.unsignedShortValue);
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    DDLogWarn(@"Monitoring failed for region %@ due to the following error: %@ (%@)", region.identifier, error.localizedDescription, error);
}

#pragma mark - CLLocationManagerDelegate (Beacon ranging) implementation

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    DDLogDebug(@"Beacons before filtering: %@", beacons);
    NSArray *rangedBeacons = [self.filter processedBeaconsFromBeacons:beacons];
    DDLogDebug(@"Beacons after filtering: %@", rangedBeacons);
    if (rangedBeacons.count > 0) {
        // Fire an event only if there's something to show
        NSDictionary *results = @{ region: rangedBeacons };
        for (MENavigationDataSourceListenerBlock listener in self.listeners) {
            listener(self.identifier, [NSValue valueWithNonretainedObject:results]);
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    DDLogWarn(@"Beacon ranging failed for region %@ due to the following error: %@ (%@)", region.identifier, error.localizedDescription, error);
}

@end
