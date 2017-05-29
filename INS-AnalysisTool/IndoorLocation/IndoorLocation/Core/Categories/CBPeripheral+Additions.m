//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "CBPeripheral+Additions.h"


@implementation CBPeripheral (Additions)

- (NSArray<CBCharacteristic *> *)characteristicsForIdentifiers:(NSArray<CBUUID *> *)identifiers
                                                    properties:(CBCharacteristicProperties)properties
{
    // Operator for array flattening
    NSString *operator = [NSString stringWithFormat:@"@%@.characteristics", NSDistinctUnionOfArraysKeyValueOperator];
    // Preparing filter for characteristics
    NSSet<CBUUID *> *characteristicUUIDs = [NSSet setWithArray:identifiers];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(CBCharacteristic *obj, NSDictionary *bindings) {
        return [characteristicUUIDs containsObject:obj.UUID];
    }];
    return [[self.services valueForKeyPath:operator] filteredArrayUsingPredicate:predicate];
}

@end