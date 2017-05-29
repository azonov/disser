//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
#import <CoreBluetooth/CoreBluetooth.h>

@interface NSObject(WCProtocolType)
+ (NSString *)keyPathForPropertyImplementingProtocol:(Protocol *)aProtocol;
- (NSString *)keyPathForPropertyImplementingProtocol:(Protocol *)aProtocol;
@end

// Implements one-to-many dispatch where it's necessary to provide partial implementation of the protocol
@interface WCMulticastDelegate : NSProxy <CBPeripheralDelegate>
- (instancetype)initWithProtocol:(Protocol *)aProtocol observable:(id)observable;
- (void)addDelegate:(id)listener;
- (void)removeDelegate:(id)listener;
@end