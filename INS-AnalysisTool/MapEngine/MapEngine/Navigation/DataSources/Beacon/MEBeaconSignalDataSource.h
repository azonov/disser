//
// Created by Yaroslav Vorontsov on 17.10.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MENavigationDataSource.h"

/**
 * This data source provides with a set of filtered beacon measurements
 */
@interface MEBeaconSignalDataSource : NSObject <MENavigationDataSource>
@end