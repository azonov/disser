//
// Created by Yaroslav Vorontsov on 31.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCSerializerFactory.h"
#import "ConnectionDataSerializer.h"
#import "WCPeripheralConnection.h"
#import "WCWellcoreSerializer.h"


@implementation WCSerializerFactory
{

}

+ (id <ConnectionDataSerializer>)serializerForConnection:(id <WCPeripheralConnection>)connection
{
    return [WCWellcoreSerializer new];
}

@end