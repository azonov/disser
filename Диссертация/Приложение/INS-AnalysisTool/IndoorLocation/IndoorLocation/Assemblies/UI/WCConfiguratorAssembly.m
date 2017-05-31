//
// Created by Yaroslav Vorontsov on 29.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCConfiguratorAssembly.h"
#import "WCCoreProvider.h"
#import "WCBeaconListViewController.h"


@implementation WCConfiguratorAssembly
{

}

- (UIViewController *)beaconsViewController
{
    return [TyphoonDefinition withClass:[WCBeaconListViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(discoveryService) with:self.coreProvider.discoveryService];
    }];
}

@end