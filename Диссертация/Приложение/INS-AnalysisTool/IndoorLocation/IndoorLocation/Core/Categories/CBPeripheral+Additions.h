//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral (Additions)
- (NSArray<CBCharacteristic *> *)characteristicsForIdentifiers:(NSArray<CBUUID *> *)identifiers
                                                    properties:(CBCharacteristicProperties)properties;
@end