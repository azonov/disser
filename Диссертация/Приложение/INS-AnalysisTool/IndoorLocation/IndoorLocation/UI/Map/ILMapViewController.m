//
//  ILMapViewController.m
//  MapPoC
//
//  Created by Yaroslav Vorontsov on 08.04.15.
//  Copyright (c) 2015 DataArt. All rights reserved.
//

@import CocoaLumberjack;
@import MapEngine;

#import "ILMapViewController.h"
#import "ILConstants.h"

@interface ILMapViewController ()
@property (weak, nonatomic) IBOutlet METiledMapView *mapView;
@end

@implementation ILMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"VrnMap" ofType:@"bundle"];
    MEMapBundle *mapBundle = [[MEMapBundle alloc] initWithPath:bundlePath];
    self.mapView.mapBundle = mapBundle;
    self.mapView.trackUserLocation = YES;
    self.mapView.showBeacons = YES;
    DDLogDebug(@"Loaded class %@", NSStringFromClass([self class]));
}

@end