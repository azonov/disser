//
// Created by Yaroslav Vorontsov on 06.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;
#import "ILConstants.h"

@class HardwareDescription;
@protocol HardwareInfo;

typedef void (^CBCharacteristicCompletionBlock)(NSDictionary<CBUUID *, NSData *>*, NSDictionary<CBUUID *, NSError *>*);

/**
 * Encapsulates the information about the connection.
 * RSSI and deviceName are KVO-compliant
 */
@protocol WCPeripheralConnection
@property (strong, nonatomic, readonly) id<HardwareInfo> hardware;
@property (copy, nonatomic, readonly) NSString *connectionId;
@property (copy, nonatomic, readonly) NSString *deviceName;
@property (assign, nonatomic, readonly) NSInteger rssi;
@property (assign, nonatomic, readonly) BOOL requiresPassword;
- (void)updateConnectionInformation;
- (void)authenticateWithPassword:(NSData *)passwordData completion:(CBCharacteristicCompletionBlock)completion;
- (void)readAllCharacteristicsWithCompletion:(CBCharacteristicCompletionBlock)completion;
- (void)readCharacteristics:(NSArray<CBUUID *>*)characteristics
                 completion:(CBCharacteristicCompletionBlock)completion;
- (void)writeValuesForCharacteristics:(NSDictionary<CBUUID *, NSData *>*)values
                           completion:(CBCharacteristicCompletionBlock)completion;
- (void)cancelIOTransactions;
@optional
@end

@interface WCPeripheralConnection : NSObject <WCPeripheralConnection, CBPeripheralDelegate>
@property (strong, nonatomic, readonly) CBPeripheral *peripheral;
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral hardware:(id <HardwareInfo>)hardware rssi:(NSNumber *)rssi;
@end