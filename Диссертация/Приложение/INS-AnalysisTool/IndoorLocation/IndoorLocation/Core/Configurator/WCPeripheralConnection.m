//
// Created by Yaroslav Vorontsov on 06.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

@import CocoaLumberjack;
#import "WCPeripheralConnection.h"
#import "HardwareInfo.h"
#import "WCMulticastDelegate.h"
#import "WCDataReadOperation.h"
#import "WCCharacteristicDiscoveryOperation.h"
#import "WCDataWriteOperation.h"

@interface WCPeripheralConnection()
@property (strong, nonatomic, readonly) NSMutableDictionary *characteristics;
@property (strong, nonatomic, readonly) NSOperationQueue *interactionQueue;
@property (strong, nonatomic, readonly) WCMulticastDelegate *dispatchDelegate;
@end

@implementation WCPeripheralConnection
{
    NSOperationQueue *_interactionQueue;
}
@synthesize hardware = _hardware;
@synthesize rssi = _rssi;

#pragma mark - Initialization and memory management

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral hardware:(id <HardwareInfo>)hardware rssi:(NSNumber *)rssi
{
    if ((self = [super init]))
    {
        _hardware = hardware;
        _peripheral = peripheral;
        _dispatchDelegate = [[WCMulticastDelegate alloc] initWithProtocol:@protocol(CBPeripheralDelegate)
                                                               observable:peripheral];
        [_dispatchDelegate addDelegate:self];
        _rssi = [rssi integerValue];
        _characteristics = [@{} mutableCopy];
    }
    return self;
}

- (void)dealloc
{
    [_dispatchDelegate removeDelegate:self];
    _peripheral.delegate = nil;
    [_interactionQueue cancelAllOperations];
}

#pragma mark - Overridden getters and setters

- (NSOperationQueue *)interactionQueue
{
    if (!_interactionQueue) {
        _interactionQueue = [[NSOperationQueue alloc] init];
        _interactionQueue.name = @"com.dataart.wellcore-calibrator:peripheral-connection";
        _interactionQueue.maxConcurrentOperationCount = 1;
        _interactionQueue.qualityOfService = NSQualityOfServiceUtility;
    }
    return _interactionQueue;
}

- (NSString *)connectionId
{
    return self.peripheral.identifier.UUIDString;
}

- (NSString *)deviceName
{
    return self.peripheral.name;
}

- (BOOL)requiresPassword
{
    return self.hardware.requiresPassword;
}

#pragma mark - Configuration methods

- (void)updateConnectionInformation
{
    [self.peripheral readRSSI];
}

- (void)authenticateWithPassword:(NSData *)passwordData completion:(CBCharacteristicCompletionBlock)completion
{
    NSParameterAssert(passwordData != nil);
    NSParameterAssert(completion != nil);
    NSDictionary *values = @{ self.hardware.passwordServiceID : passwordData };
    WCDataWriteOperation *writeOperation = [[[WCDataWriteOperation alloc] initWithPeripheral:self.peripheral
                                                                                      values:values]
            setCompletionCallback:[self callbackForCompletionBlock:completion]];
    [self.dispatchDelegate addDelegate:writeOperation];
    [self launchCommunicationOperation:writeOperation];
}

- (void)readAllCharacteristicsWithCompletion:(CBCharacteristicCompletionBlock)completion
{
    NSString *collectionOperator = [NSString stringWithFormat:@"@%@.identifier", NSDistinctUnionOfArraysKeyValueOperator];
    NSArray *allCharacteristics = [self.hardware.characteristics.allValues valueForKeyPath:collectionOperator];
    [self readCharacteristics:allCharacteristics completion:completion];
}

- (void)readCharacteristics:(NSArray<CBUUID *> *)characteristics completion:(CBCharacteristicCompletionBlock)completion
{
    // https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/index.html#//apple_ref/occ/instp/CBPeripheral
    NSParameterAssert(completion != nil);
    WCDataReadOperation *readOperation = [[[WCDataReadOperation alloc] initWithPeripheral:self.peripheral
                                                                          characteristics:characteristics]
            setCompletionCallback:[self callbackForCompletionBlock:completion]];
    [self.dispatchDelegate addDelegate:readOperation];
    [self launchCommunicationOperation:readOperation];
}

- (void)writeValuesForCharacteristics:(NSDictionary<CBUUID *, NSData *> *)values completion:(CBCharacteristicCompletionBlock)completion
{
    // Use the same mechanism which is used inside read operation
    NSParameterAssert(completion != nil);
    WCDataWriteOperation *writeOperation = [[[WCDataWriteOperation alloc] initWithPeripheral:self.peripheral
                                                                                      values:values]
            setCompletionCallback:[self callbackForCompletionBlock:completion]];
    [self.dispatchDelegate addDelegate:writeOperation];
    [self launchCommunicationOperation:writeOperation];
}

- (void)cancelIOTransactions
{
    [self.interactionQueue cancelAllOperations];
}

#pragma mark - Helper methods

- (NSOperation *)makeDiscoveryOperation
{
    NSOperation *op = [[WCCharacteristicDiscoveryOperation alloc] initWithPeripheral:self.peripheral
                                                                  servicesToDiscover:@[self.hardware.primaryServiceID]];
    [self.dispatchDelegate addDelegate:op];
    return op;
}

- (void)launchCommunicationOperation:(WCCoreBluetoothOperation *)operation
{
    // Test that services have already been discovered or discover them and continue. Read the documentation for more details:
    if (self.peripheral.services != nil) {
        [self.interactionQueue addOperation:operation];
    } else {
        NSOperation *discoveryOperation = [self makeDiscoveryOperation];
        [operation addDependency:discoveryOperation];
        [self.interactionQueue addOperations:@[discoveryOperation, operation] waitUntilFinished:NO];
    }
}

// Splits read/written values and read/write errors
- (WCCoreBluetoothOperationCompletionBlock)callbackForCompletionBlock:(CBCharacteristicCompletionBlock)block
{
    NSParameterAssert(block != nil);
    return ^(NSDictionary<CBUUID *, id> *dictionary) {
        NSMutableDictionary<CBUUID *, NSData *> *values = [NSMutableDictionary dictionary];
        NSMutableDictionary<CBUUID *, NSError *> *errors = [NSMutableDictionary dictionary];
        [dictionary enumerateKeysAndObjectsUsingBlock:^(CBUUID *key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[NSData class]]) {
                values[key] = obj;
            } else if ([obj isKindOfClass:[NSError class]]) {
                errors[key] = obj;
            } else {
                DDLogWarn(@"Unregistered object type found: expected NSData or NSError, got %@", NSStringFromClass([obj class]));
            }
        }];
        block([values copy], [errors copy]);
    };
}

#pragma mark - CBPeripheralDelegate implementation

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    DDLogDebug(@"Peripheral %@ has changed its name to %@", peripheral.identifier.UUIDString, peripheral.name);
    NSString *deviceNameKey = NSStringFromSelector(@selector(deviceName));
    [self willChangeValueForKey:deviceNameKey];
    [self didChangeValueForKey:deviceNameKey];
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    if (error != nil) {
        DDLogWarn(@"Failed to read RSSI due to the following error: %@ (%@)", error.localizedDescription, error);
    } else {
        NSString *rssiKey = NSStringFromSelector(@selector(rssi));
        [self willChangeValueForKey:rssiKey];
        _rssi = RSSI.integerValue;
        [self didChangeValueForKey:rssiKey];
    }
}

@end