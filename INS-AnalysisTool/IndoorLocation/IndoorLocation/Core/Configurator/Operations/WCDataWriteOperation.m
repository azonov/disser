//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import CocoaLumberjack;
#import "WCDataWriteOperation.h"
#import "ILConstants.h"
#import "CBPeripheral+Additions.h"

@interface WCDataWriteOperation()
@property (strong, nonatomic, readonly) NSDictionary *values;
@property (assign, nonatomic) NSUInteger valueCount;
@end

@implementation WCDataWriteOperation

#pragma mark - Initialization

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral values:(NSDictionary<CBUUID *, NSData *> *)values
{
    if ((self = [super initWithPeripheral:peripheral])) {
        _values = values;
        _valueCount = values.count;
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
        CBCharacteristicProperties properties = CBCharacteristicPropertyWrite | CBCharacteristicPropertyWriteWithoutResponse;
        NSArray<CBCharacteristic *> *writeableCharacteristics = [self.peripheral characteristicsForIdentifiers:self.values.allKeys
                                                                                                    properties:properties];
        if (writeableCharacteristics.count > 0) {
            for (CBCharacteristic *characteristic in writeableCharacteristics) {
                // 0 - with response, 1 - without response
                CBCharacteristicWriteType writeType = (CBCharacteristicWriteType) (characteristic.properties
                        & CBCharacteristicPropertyWriteWithoutResponse);
                if (writeType > 0) {
                    --self.valueCount;
                }
                // The default assignment will be replaced by an NSError in case of failure, so that's OK
                [self.peripheral writeValue:(self.results[characteristic.UUID] = self.values[characteristic.UUID])
                          forCharacteristic:characteristic
                                       type:writeType];
            }
            // Additional check because some characteristics may be written without confirmation
            if (self.valueCount == 0) {
                [self finish];
            }
        } else {
            [self finish];
        }
    }
}

#pragma mark - CBPeripheralDelegate implementation

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (self.cancelled) {
        [self finish];
    } else {
        if (error != nil) {
            self.results[characteristic.UUID] = error;
            DDLogWarn(@"Failed to write characteristic %@ due to the following error: %@ (%@)",
                    characteristic, error.localizedDescription, error);
        } else {
            DDLogDebug(@"Updated characteristic %@ for peripheral %@", characteristic, peripheral);
        }
        --self.valueCount;
        if (self.valueCount == 0) {
            [self finish];
        }
    }
}

@end