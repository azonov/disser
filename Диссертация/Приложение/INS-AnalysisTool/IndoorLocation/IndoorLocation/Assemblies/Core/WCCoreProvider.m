//
// Created by Yaroslav Vorontsov on 01.06.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCCoreProvider.h"
#import "WCBeaconRanger.h"
#import "WCCSVDataGrabber.h"
#import "WCSensorFusion.h"
#import "WCDiscoveryManager.h"


@implementation WCCoreProvider
{

}

- (id <WCBeaconRanger>)rangingService
{
    return [TyphoonDefinition withClass:[WCBeaconRanger class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithCSVGrabber:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self logGatheringService]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (id <WCCSVDataGrabber>)logGatheringService
{
    return [TyphoonDefinition withClass:[WCCSVDataGrabber class] configuration:^(TyphoonDefinition *definition) {
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (id <WCSensorFusion>)sensorService
{
    return [TyphoonDefinition withClass:[WCSensorFusion class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithDataGrabber:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self logGatheringService]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (id <WCDiscoveryManager>)discoveryService
{
    return [TyphoonDefinition withClass:[WCDiscoveryManager class] configuration:^(TyphoonDefinition *definition) {
        definition.scope = TyphoonScopeSingleton;
    }];
}


@end