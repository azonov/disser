//
// Created by Yaroslav Vorontsov on 17.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
#import "WCInteractor.h"
#import "ILConstants.h"

@protocol WCDiscoveryManager;
@protocol HardwareInfo;
@class WCListDataSource;
@class WCPeripheralSelectionInteractor;

@protocol WCPeripheralInteractionDelegate <NSObject>
@optional
- (void)interactorDidConnectToPeripheral:(WCPeripheralSelectionInteractor *)interactor;
- (void)interactorDidDisconnectFromPeripheral:(WCPeripheralSelectionInteractor *)interactor;
@end

@interface WCPeripheralSelectionInteractor : WCInteractor
@property (weak, nonatomic) id<WCPeripheralInteractionDelegate> delegate;
@property (assign, nonatomic, readonly) BOOL rangingEnabled;
- (instancetype)initWithDiscoveryService:(id <WCDiscoveryManager>)discoveryService;
- (instancetype)bindToDataSource:(WCListDataSource *)dataSource;
- (void)startDiscoveryForHardware:(id<HardwareInfo>)hardware;
@end