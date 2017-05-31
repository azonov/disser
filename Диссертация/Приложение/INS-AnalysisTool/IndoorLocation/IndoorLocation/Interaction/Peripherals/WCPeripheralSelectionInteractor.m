//
// Created by Yaroslav Vorontsov on 17.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import libextobjc;
@import KVOController;
#import "WCPeripheralSelectionInteractor.h"
#import "WCDiscoveryManager.h"
#import "HardwareDescription.h"
#import "WCListDataSource.h"
#import "WCPeripheralConnection.h"

@interface WCPeripheralSelectionInteractor()
@property (strong, nonatomic, readonly) NSMutableArray *peripherals;
@property (strong, nonatomic, readonly) NSTimer *updateTimer;
@property (strong, nonatomic, readonly) id<WCDiscoveryManager> discoveryService;
@property (strong, nonatomic, readonly) NSNotificationCenter *center;
@property (strong, nonatomic, readonly) FBKVOController *connectionObserver;
@property (weak, nonatomic, readonly) WCListDataSource *dataSource;
@end

@implementation WCPeripheralSelectionInteractor

#pragma mark - Initialization and deallocation

- (instancetype)initWithDiscoveryService:(id <WCDiscoveryManager>)discoveryService
{
    if ((self = [super init])) {
        _discoveryService = discoveryService;
        _center = [NSNotificationCenter defaultCenter];
        _peripherals = [NSMutableArray array];
        _connectionObserver = [FBKVOController controllerWithObserver:self];
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:self
                                                      selector:@selector(timerDidFire:)
                                                      userInfo:nil
                                                       repeats:YES];
        [_center addObserver:self
                    selector:@selector(didConnectPeripheral:)
                        name:WCDiscoveryManagerNotifications.peripheralConnected
                      object:_discoveryService];
        [_center addObserver:self
                    selector:@selector(didDisconnectPeripheral:)
                        name:WCDiscoveryManagerNotifications.peripheralDisconnected
                      object:_discoveryService];
    }
    return self;
}

- (void)dealloc
{
    [_center removeObserver:self];
    [_updateTimer invalidate];
    [_discoveryService stopDiscovery];
}

#pragma mark - Overridden getters and setters

- (BOOL)rangingEnabled
{
    return self.discoveryService.scanning;
}

#pragma mark - Chaining methods

- (instancetype)bindToDataSource:(WCListDataSource *)dataSource
{
    _dataSource = dataSource;
    return self;
}

#pragma mark - Handling timer notifications

- (void)timerDidFire:(NSTimer *)timer
{
    [self.peripherals makeObjectsPerformSelector:@selector(updateConnectionInformation)];
}

#pragma mark - Handling ranging and peripheral notifications

- (void)didConnectPeripheral:(NSNotification *)notification
{
    if (self.rangingEnabled) {
        id<WCPeripheralConnection> connection = notification.userInfo[WCDiscoveryManagerNotifications.Keys.connection];
        [_peripherals addObject:connection];
        // Subscribe to the updates of name and RSSI
        [self.connectionObserver observe:connection
                                keyPaths:@[@"deviceName", @"rssi"]
                                 options:NSKeyValueObservingOptionNew
                                  action:@selector(stateDidChange:forConnection:)];
        @weakify(self);
        [self.callbackQueue addOperationWithBlock:^{
            @strongify(self);
            [self.dataSource appendItem:connection];
            [self notifyAboutConnection];
        }];
    }
}

- (void)didDisconnectPeripheral:(NSNotification *)notification
{
    if (self.rangingEnabled) {
        id<WCPeripheralConnection> connection = notification.userInfo[WCDiscoveryManagerNotifications.Keys.connection];
        [self.connectionObserver unobserve:connection];
        // Though it's safe to send messages to nil, it's better to prevent extra O(N) search inside an array
        NSUInteger index = [self.peripherals indexOfObject:connection];
        [_peripherals removeObject:connection];
        if (self.dataSource != nil && index != NSNotFound) {
            @weakify(self);
            [self.callbackQueue addOperationWithBlock:^{
                @strongify(self);
                [self.dataSource removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
                [self notifyAboutDisconnection];
            }];
        }
    }
}

- (void)stateDidChange:(NSDictionary *)state forConnection:(id <WCPeripheralConnection>)connection
{
    NSUInteger index = [self.peripherals indexOfObject:connection];
    if (self.dataSource != nil && index != NSNotFound) {
        @weakify(self);
        [self.callbackQueue addOperationWithBlock:^{
            @strongify(self);
            [self.dataSource reloadItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
        }];
    }
}

#pragma mark - Interaction methods

- (void)startDiscoveryForHardware:(id<HardwareInfo>)hardware
{
    if (!self.rangingEnabled) {
        [self.discoveryService startDiscoveryForHardware:@[hardware]];
    }
}

#pragma mark - External notifications

- (void)notifyAboutConnection
{
    if ([self.delegate respondsToSelector:@selector(interactorDidConnectToPeripheral:)]) {
        [self.delegate interactorDidConnectToPeripheral:self];
    }
}

- (void)notifyAboutDisconnection
{
    if ([self.delegate respondsToSelector:@selector(interactorDidDisconnectFromPeripheral:)]) {
        [self.delegate interactorDidDisconnectFromPeripheral:self];
    }
}

@end