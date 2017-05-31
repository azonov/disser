//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

typedef void (^WCCoreBluetoothOperationCompletionBlock)(NSDictionary<CBUUID *, id>*);

// Implements a basic concurrent operation for CoreBluetooth transactions
@interface WCCoreBluetoothOperation : NSOperation
@property (strong, nonatomic, readonly) CBPeripheral *peripheral;
@property (strong, nonatomic, readonly) NSMutableDictionary *results;
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral;
- (instancetype)setCompletionCallback:(WCCoreBluetoothOperationCompletionBlock)callback;
- (void)finish;
@end