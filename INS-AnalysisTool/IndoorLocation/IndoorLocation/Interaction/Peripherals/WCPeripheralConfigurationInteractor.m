//
// Created by Yaroslav Vorontsov on 22.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import XLForm;
@import libextobjc;
@import CocoaLumberjack;
#import "WCPeripheralConfigurationInteractor.h"
#import "WCPeripheralConnection.h"
#import "HardwareDescription.h"
#import "WCWellcoreSerializer.h"
#import "WCSerializerFactory.h"
#import "CollectionUtils.h"

@interface WCPeripheralConfigurationInteractor()
@property (strong, nonatomic, readonly) id<WCPeripheralConnection> connection;
@property (strong, nonatomic, readonly) id<ConnectionDataSerializer> serializer;
@property (strong, nonatomic, readonly) NSDictionary *formTypeMapping;
@end

@implementation WCPeripheralConfigurationInteractor

#pragma mark - Initialization and memory management

- (instancetype)initWithConnection:(id <WCPeripheralConnection>)connection
{
    if ((self = [super init])) {
        _serializer = [WCSerializerFactory serializerForConnection:connection];
        _connection = connection;
        _connectionStatus = @"Connected";
        _formTypeMapping = @{
                CharacteristicType.constant: XLFormRowDescriptorTypeInfo,
                CharacteristicType.text: XLFormRowDescriptorTypeText,
                CharacteristicType.number: XLFormRowDescriptorTypeInteger,
                CharacteristicType.range: XLFormRowDescriptorTypeSlider,
                CharacteristicType.action: XLFormRowDescriptorTypeButton
        };
    }
    return self;
}

#pragma mark - Public methods

- (NSString *)formTypeForCharacteristic:(CharacteristicDescription *)description
{
    return self.formTypeMapping[description.type] ?: XLFormRowDescriptorTypeName;
}

- (void)authenticateWithPassword:(NSString *)password
{
    NSData *passwordData = [self.serializer dataForAuthenticationWithPassword:password];
    [self notifyDidStartTransactionWithStatus:@"Authenticating"];
    @weakify(self);
    [self.connection authenticateWithPassword:passwordData completion:^(NSDictionary<CBUUID *, NSData *> *response,
            NSDictionary<CBUUID *, NSError *> *errors) {
        @strongify(self);
        [self readAllCharacteristics];
        [self notifyDidFinishTransactionWithValues:response errors:errors];
    }];
}

- (void)readAllCharacteristics
{
    [self notifyDidStartTransactionWithStatus:@"Reading characteristics"];
    @weakify(self);
    [self.connection readAllCharacteristicsWithCompletion:^(NSDictionary<CBUUID *, NSData *> *response,
            NSDictionary<CBUUID *, NSError *> *errors) {
        @strongify(self);
        NSDictionary<CBUUID *, id> *values = [response keyedMap:^id(CBUUID *key, NSData *value) {
            return [self.serializer valueForData:value characteristic:key];
        }];
        DDLogDebug(@"Finished reading values");
        [self notifyDidFinishTransactionWithValues:values errors:errors];
    }];
}

- (void)writeCharacteristics:(NSDictionary<CBUUID *, id> *)characteristics
{
    [self notifyDidStartTransactionWithStatus:@"Writing characteristics"];
    // Translate into binary format
    NSDictionary<CBUUID *, NSData *> *values = [characteristics keyedMap:^id(CBUUID *key, id value) {
        return [self.serializer dataForValue:value characteristic:key];
    }];
    @weakify(self);
    [self.connection writeValuesForCharacteristics:values completion:^(NSDictionary<CBUUID *, NSData *> *response,
            NSDictionary<CBUUID *, NSError *> *errors) {
        @strongify(self);
        DDLogDebug(@"Finished writing values");
        [self notifyDidFinishTransactionWithValues:nil errors:errors];
    }];
}

- (void)cancelAllPendingTransactions
{
    DDLogDebug(@"Cancelling ALL Bluetooth read/write operations");
    [self.connection cancelIOTransactions];
}

#pragma mark - Delegate notifications

- (void)notifyDidStartTransactionWithStatus:(NSString *)status
{
    _connectionStatus = [status copy];
    if ([self.delegate respondsToSelector:@selector(interactorDidStartTransaction:)]) {
        @weakify(self);
        [self.callbackQueue addOperationWithBlock:^{
            @strongify(self);
            [self.delegate interactorDidStartTransaction:self];
        }];
    }
}

- (void)notifyDidFinishTransactionWithValues:(NSDictionary<CBUUID *, id> *)values
                                      errors:(NSDictionary<CBUUID *, NSError *> *)errors
{
    if ([self.delegate respondsToSelector:@selector(interactorDidFinishTransaction:withValues:errors:)]) {
        @weakify(self);
        [self.callbackQueue addOperationWithBlock:^{
            @strongify(self);
            [self.delegate interactorDidFinishTransaction:self withValues:values errors:errors];
        }];
    }
}

@end