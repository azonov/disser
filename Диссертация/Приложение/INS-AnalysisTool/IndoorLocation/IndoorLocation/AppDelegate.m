//
//  AppDelegate.m
//  WellcoreCalibrator
//
//  Created by Yaroslav Vorontsov on 30.05.16.
//  Copyright © 2016 DataArt. All rights reserved.
//


#import "AppDelegate.h"
#import "ILConstants.h"
#import "WCBeaconRanger.h"
#import "WCCSVDataGrabber.h"

@import CocoaLumberjack;

@interface AppDelegate ()
@property (strong, nonatomic, readwrite) id<WCCSVDataGrabber> csvGrabber;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch
    DDLogDebug(@"Application has finished launching");
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of
    // temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application
    // and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates.
    // Games should use this method to pause the game.
    DDLogDebug(@"Application will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application
    // state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called
    // instead of applicationWillTerminate: when the user quits.
    DDLogDebug(@"Application entered background; flushing all log files");
    [DDLog flushLog];
    [self.csvGrabber flushLogs];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state;
    // here you can undo many of the changes made on entering the background.
    DDLogDebug(@"Application will enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive.
    // If the application was previously in the background, optionally refresh the user interface.
    DDLogDebug(@"Application has become active");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate.
    // See also applicationDidEnterBackground:.
    DDLogDebug(@"Application will terminate soon. Logs will be flushed automatically");
}

@end