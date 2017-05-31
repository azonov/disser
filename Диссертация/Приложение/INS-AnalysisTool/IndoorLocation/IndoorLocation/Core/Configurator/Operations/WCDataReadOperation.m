//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import CocoaLumberjack;
#import "WCDataReadOperation.h"
#import "ILConstants.h"
#import "CBPeripheral+Additions.h"

@interface WCDataReadOperation()
@property (strong, nonatomic, readonly) NSArray *characteristics;
@property (assign, nonatomic) NSUInteger characteristicCount;
@end

@implementation WCDataReadOperation

#pragma mark - Initialization

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral characteristics:(NSArray<CBUUID *> *)characteristics
{
    if ((self = [super initWithPeripheral:peripheral])) {
        _characteristics = characteristics;
        _characteristicCount = characteristics.count;
    }
    return self;
}

#pragma mark - Main methods

- (void)main
{
    if (self.cancelled) {
        [self finish];
    } else {
        // Make sure that services were already discovered
        NSParameterAssert(self.peripheral.services != nil);
        NSArray<CBCharacteristic *> *readableCharacteristics = [self.peripheral characteristicsForIdentifiers:self.characteristics
                                                                                                   properties:CBCharacteristicPropertyRead];
        if (readableCharacteristics.count > 0) {
            for (CBCharacteristic *characteristic in readableCharacteristics) {
                [self.peripheral readValueForCharacteristic:characteristic];
            }
        } else {
            [self finish];
        }
    }
}

#pragma mark - CBPeripheralDelegate implementation

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (self.cancelled) {
        [self finish];
    } else {
        if (error != nil) {
            self.results[characteristic.UUID] = error;
            DDLogWarn(@"Failed to update value for characteristic %@ due to the following error: %@ (%@)",
                    characteristic, error.localizedDescription, error);
        } else {
            self.results[characteristic.UUID] = characteristic.value;
            DDLogDebug(@"Fetched value for characteristic %@", characteristic);
        }
        --self.characteristicCount;
        if (self.characteristicCount == 0) {
            [self finish];
        }
    }
}

@end