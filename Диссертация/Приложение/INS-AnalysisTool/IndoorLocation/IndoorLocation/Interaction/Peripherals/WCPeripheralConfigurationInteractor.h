//
// Created by Yaroslav Vorontsov on 22.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;
#import "WCInteractor.h"

@protocol WCPeripheralConnection;
@class CharacteristicDescription;
@class HardwareDescription;
@class WCPeripheralConfigurationInteractor;

@protocol WCConfigurationInteractorDelegate <NSObject>
@optional
- (void)interactorDidStartTransaction:(WCPeripheralConfigurationInteractor *)interactor;
- (void)interactorDidFinishTransaction:(WCPeripheralConfigurationInteractor *)interactor
                            withValues:(NSDictionary<CBUUID *, id> *)values
                                errors:(NSDictionary<CBUUID *, NSError *> *)errors;
@end

@interface WCPeripheralConfigurationInteractor : WCInteractor
@property (copy, nonatomic, readonly) NSString *connectionStatus;
@property (weak, nonatomic) id<WCConfigurationInteractorDelegate> delegate;
- (instancetype)initWithConnection:(id <WCPeripheralConnection>)connection;
- (NSString *)formTypeForCharacteristic:(CharacteristicDescription *)description;
- (void)authenticateWithPassword:(NSString *)password;
- (void)readAllCharacteristics;
- (void)writeCharacteristics:(NSDictionary<CBUUID *, id> *)characteristics;
- (void)cancelAllPendingTransactions;
@end