//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;
#import "WCCoreBluetoothOperation.h"

@interface WCDataWriteOperation : WCCoreBluetoothOperation <CBPeripheralDelegate>
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral values:(NSDictionary<CBUUID *, NSData *> *)values;
@end