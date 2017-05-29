//
// Created by Yaroslav Vorontsov on 30.05.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCBeaconRanger.h"
#import "ILConstants.h"
#import "WCCSVDataGrabber.h"

const struct WCBeaconRangerNotifications WCBeaconRangerNotifications = {
        .beaconsRanged = @"WCBeaconRanger=>BeaconsRanged"
};

@interface WCBeaconRanger()
@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@end

@implementation WCBeaconRanger
{
    CLLocationManager *_locationManager;
    id<WCCSVDataGrabber> _grabber;
}

#pragma mark - Initialization

- (instancetype)initWithCSVGrabber:(id<WCCSVDataGrabber>)grabber
{
    if ((self = [super init])) {
        _grabber = grabber;
    }
    return self;
}

#pragma mark - Overridden getters/setters


- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [CLLocationManager new];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

#pragma mark - Implementation of the protocol

- (void)startTrackingRegion:(CLBeaconRegion *)region
{
    [self.locationManager startMonitoringForRegion:region];
}

- (void)stopTrackingRegion:(CLBeaconRegion *)region
{
    [self.locationManager stopMonitoringForRegion:region];
}

#pragma mark - CLLocationManager - region monitoring

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    DDLogDebug(@"Monitoring has been started for region %@", region.identifier);
    [manager performSelector:@selector(requestStateForRegion:) withObject:region];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *) region;
        DDLogInfo(@"App tracked a change for region %@ (UUID %@)", beaconRegion.identifier, beaconRegion.proximityUUID.UUIDString);
        switch (state) {
            case CLRegionStateInside:
                DDLogInfo(@"Starting ranging beacons");
                [manager startRangingBeaconsInRegion:beaconRegion];
                break;
            case CLRegionStateOutside:
                DDLogInfo(@"Stopping ranging beacons");
                [manager stopRangingBeaconsInRegion:beaconRegion];
                break;
            default:
                DDLogInfo(@"State is not determined");
                break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *) region;
        DDLogInfo(@"App tracked an entry to region %@ (UUID %@)", beaconRegion.identifier, beaconRegion.proximityUUID.UUIDString);
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *) region;
        DDLogInfo(@"App tracked an exit from region %@ (UUID %@)", beaconRegion.identifier, beaconRegion.proximityUUID.UUIDString);
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    DDLogWarn(@"Location manager has failed to monitor region %@ due to an error: %@ (%@)", region.identifier, error.localizedDescription, error);
}

#pragma mark - CLLocationManager - Beacon ranging

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region
{
    DDLogDebug(@"Ranged %tu beacons from region %@", beacons.count, region.identifier);
    if (beacons.count > 0) {
        NSNumber *timestamp = @([NSDate date].timeIntervalSince1970);
        for (CLBeacon *beacon in beacons) {
            [_grabber writeValues:@[
                    timestamp.stringValue,
                    [NSString stringWithFormat:@"%@.%@", beacon.major.stringValue, beacon.minor.stringValue],
                    @(beacon.proximity),
                    @(beacon.accuracy),
                    @(beacon.rssi)
            ]];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:WCBeaconRangerNotifications.beaconsRanged object:self];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    DDLogWarn(@"Beacon monitoring in region %@ failed due to an error: %@, (%@)", region.identifier, error.localizedDescription, error);
}

#pragma mark - CLLocationManager - General methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    DDLogInfo(@"Location manager's state has changed to %d", status);
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            [manager requestAlwaysAuthorization];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            DDLogDebug(@"Location services are already authorized for this app, continuing...");
            break;
        default:
            DDLogWarn(@"Unsuitable response received from location services. Go to Settings to authorize");
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DDLogWarn(@"Location manager failed with an error: %@ (%@)", error.localizedDescription, error);
}


@end