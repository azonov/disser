//
// Created by Yaroslav Vorontsov on 29.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import CoreLocation;
#import "WCExperimentsAssembly.h"
#import "WCExperimentsViewController.h"
#import "WCCoreProvider.h"


@implementation WCExperimentsAssembly
{

}

- (CLBeaconRegion *)rangedRegion
{
    NSUUID *regionUUID = [[NSUUID alloc] initWithUUIDString:@"F3CA5FB7-0933-4D65-96E5-7EAF278B1EF7"];
    return [[CLBeaconRegion alloc] initWithProximityUUID:regionUUID
                                                   major:4
                                              identifier:@"DABeacons"];
}

- (UIViewController *)experimentsViewController
{
    return [TyphoonDefinition withClass:[WCExperimentsViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(rangingService) with:self.coreProvider.rangingService];
        [definition injectProperty:@selector(csvGrabber) with:self.coreProvider.logGatheringService];
        [definition injectProperty:@selector(sensorService) with:self.coreProvider.sensorService];
        [definition injectProperty:@selector(rangedRegion) with:self.rangedRegion];
    }];
}

@end