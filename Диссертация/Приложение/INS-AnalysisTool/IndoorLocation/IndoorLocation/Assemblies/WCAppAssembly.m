//
// Created by Yaroslav Vorontsov on 01.06.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCAppAssembly.h"
#import "WCCoreProvider.h"
#import "AppDelegate.h"
#import "WCExperimentsViewController.h"

@implementation WCAppAssembly

- (AppDelegate *)appDelegate
{
    return [TyphoonDefinition withClass:[AppDelegate class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(csvGrabber) with:self.coreProvider.logGatheringService];
    }];
}

@end