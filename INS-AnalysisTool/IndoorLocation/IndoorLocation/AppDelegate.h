//
//  AppDelegate.h
//  WellcoreCalibrator
//
//  Created by Yaroslav Vorontsov on 30.05.16.
//  Copyright © 2016 DataArt. All rights reserved.
//

@import UIKit;

@protocol WCBeaconRanger;
@protocol WCCSVDataGrabber;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) id<WCCSVDataGrabber> csvGrabber;
@end