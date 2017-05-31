//
//  ViewController.h
//  WellcoreCalibrator
//
//  Created by Yaroslav Vorontsov on 30.05.16.
//  Copyright © 2016 DataArt. All rights reserved.
//

@import UIKit;
@import CoreLocation;

@protocol WCCSVDataGrabber;
@protocol WCBeaconRanger;
@protocol WCSensorFusion;

@interface WCExperimentsViewController : UIViewController
@property (strong, nonatomic, readonly) CLBeaconRegion *rangedRegion;
@property (strong, nonatomic, readonly) id<WCBeaconRanger> rangingService;
@property (strong, nonatomic, readonly) id<WCCSVDataGrabber> csvGrabber;
@property (strong, nonatomic, readonly) id<WCSensorFusion> sensorService;
@end