//
// Created by Yaroslav Vorontsov on 31.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;

@protocol ConnectionDataSerializer;
@protocol WCPeripheralConnection;

@interface WCSerializerFactory : NSObject
+ (id<ConnectionDataSerializer>)serializerForConnection:(id<WCPeripheralConnection>)connection;
@end