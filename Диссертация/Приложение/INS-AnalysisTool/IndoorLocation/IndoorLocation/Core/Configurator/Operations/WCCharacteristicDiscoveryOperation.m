//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import CocoaLumberjack;
#import "WCCharacteristicDiscoveryOperation.h"
#import "ILConstants.h"

@interface WCCharacteristicDiscoveryOperation()
@property (strong, nonatomic, readonly) NSArray *services;
@property (assign, nonatomic) NSUInteger serviceCount;
@end

@implementation WCCharacteristicDiscoveryOperation

#pragma mark - Initialization

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral servicesToDiscover:(NSArray<CBUUID *> *)services
{
    if ((self = [super initWithPeripheral:peripheral])) {
        _services = services;
    }
    return self;
}

#pragma mark - Main methods

- (void)main
{
    if (self.cancelled) {
        [self finish];
    } else {
        // Do full service discovery, though it's not recommended
        [self.peripheral discoverServices:(self.services.count > 0 ? self.services : nil)];
    }
}

#pragma mark - CBPeripheralDelegate implementation

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (self.cancelled) {
        [self finish];
    } else if (error != nil) {
        DDLogWarn(@"Failed to discover services due to the following error: %@ (%@)", error.localizedDescription, error);
    } else {
        DDLogDebug(@"Services are: %@", peripheral.services);
        if ((self.serviceCount = peripheral.services.count) > 0) {
            for (CBService *service in peripheral.services) {
                [peripheral discoverCharacteristics:nil forService:service];
            }
        } else {
            // Finish immediately if no services available
            [self finish];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (self.cancelled) {
        [self finish];
    } else {
        if (error != nil) {
            DDLogWarn(@"Failed to discover characteristics for service %@ due to the following error: %@ (%@)", service, error.localizedDescription, error);
        } else {
            // Need to map with UUID-s like [service.characteristics valueForKeyPath:@"UUID.UUIDString"]
            DDLogDebug(@"Discovered the following characteristics: %@", service.characteristics);
        }
        --self.serviceCount;
        if (self.serviceCount == 0) {
            [self finish];
        }
    }
}

@end