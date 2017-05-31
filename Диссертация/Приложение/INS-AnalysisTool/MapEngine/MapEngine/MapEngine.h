//
//  MapEngine.h
//  MapEngine
//
//  Created by Yaroslav Vorontsov on 20.04.15.
//  Copyright (c) 2015 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for MapEngine.
FOUNDATION_EXPORT double MapEngineVersionNumber;

//! Project version string for MapEngine.
FOUNDATION_EXPORT const unsigned char MapEngineVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MapEngine/PublicHeader.h>

#import <MapEngine/CLBeacon+Additions.h>
#import <MapEngine/Coordinates.h>
#import <MapEngine/VectorUtils.h>
#import <MapEngine/MECoordinateModifier.h>
#import <MapEngine/MEBeacon.h>
#import <MapEngine/MEMapBeacon.h>
#import <MapEngine/MEMapBundle.h>
#import "MEPositioningAlgorithm.h"
#import <MapEngine/MELocationFilter.h>
#import <MapEngine/MENavigationManager.h>
#import <MapEngine/METiledMapView.h>