//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;
#import "WCCoreBluetoothOperation.h"


@interface WCCharacteristicDiscoveryOperation : WCCoreBluetoothOperation <CBPeripheralDelegate>
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral servicesToDiscover:(NSArray<CBUUID *> *)services;
@end