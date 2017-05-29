//
// Created by Yaroslav Vorontsov on 17.04.15.
// Copyright (c) 2015 Yaroslav Vorontsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MEMapBundle;
@class METiledMapView;
@protocol MEPositioningAlgorithm;

@protocol METiledMapViewDelegate <UIScrollViewDelegate>
@optional
- (id<MEPositioningAlgorithm>)trilaterationAlgorithmForMap:(METiledMapView *)mapView;
@end

@interface METiledMapView : UIView <UIScrollViewDelegate>
// Map bundle used to display map tiles
@property (strong, nonatomic) MEMapBundle *mapBundle;
// Map delegate. Currently unused
@property (weak, nonatomic) id<METiledMapViewDelegate> delegate;
// Indicates whether map tracks user location. Default is NO
@property (assign, nonatomic) BOOL trackUserLocation;
// Indicates whether map shows debug layer with beacons. Default is NO
@property (assign, nonatomic) BOOL showBeacons;
@end