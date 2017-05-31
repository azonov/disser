//
// Created by Yaroslav Vorontsov on 19.03.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@protocol HardwareInfo;


extern const struct WCDiscoveryManagerNotifications {
    const struct {
        __unsafe_unretained NSString *const peripheral;
        __unsafe_unretained NSString *const connection;
        __unsafe_unretained NSString *const error;
    } Keys;
    __unsafe_unretained NSString *const bluetoothNotAuthorized;
    __unsafe_unretained NSString *const bluetoothNotSupported;
    __unsafe_unretained NSString *const peripheralDiscovered;
    __unsafe_unretained NSString *const peripheralConnected;
    __unsafe_unretained NSString *const peripheralDisconnected;
    __unsafe_unretained NSString *const peripheralConnectionFailed;
} WCDiscoveryManagerNotifications;


@protocol WCDiscoveryManager
@property (assign, nonatomic, readonly) BOOL scanning;
- (void)startDiscoveryForHardware:(NSArray<id<HardwareInfo>> *)hardwareInfo;
- (void)stopDiscovery;
@end

@interface WCDiscoveryManager : NSObject <WCDiscoveryManager>
@end