//
// Created by Yaroslav Vorontsov on 26.10.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "MESettingsManager.h"
#import "MEConstants.h"

@interface MESettingsManager()
@property (strong, nonatomic, readonly) NSUserDefaults *defaults;
@property (strong, nonatomic, readonly) NSNotificationCenter *center;
@property (strong, nonatomic, readonly) CMPedometer *pedometer;
@property (assign, nonatomic, readwrite) double averageStepLength;
@end

@implementation MESettingsManager
{

}

- (instancetype)init
{
    if ((self = [super init])) {
        _pedometer = [[CMPedometer alloc] init];
        _center = [NSNotificationCenter defaultCenter];
        [self initializeDefaults];
    }
    return self;
}

- (void)initializeDefaults
{
    self.positionAccuracy = 2;

    // We can calculate an average
    if ([CMPedometer isStepCountingAvailable] && [CMPedometer isDistanceAvailable]) {
        // Documentation says that this method allows getting historical data for the last 7 days
        NSDate *endDate = [NSDate date];
        NSDate *startDate = [endDate dateByAddingTimeInterval:-7*24*3600];
        typeof(self) __weak that = self;
        [self.pedometer queryPedometerDataFromDate:startDate toDate:endDate withHandler:^(CMPedometerData *pedometerData, NSError *error) {
            if (error != nil) {
                DDLogWarn(@"Failed to get pedometer data due to an error: %@ (%@)", error.localizedDescription, error);
            } else {
                that.averageStepLength = pedometerData.distance.doubleValue / pedometerData.numberOfSteps.doubleValue;
                DDLogInfo(@"Calculated an average step length: %.3f m.", that.averageStepLength);
            }
        }];
    } else {
        self.averageStepLength = 0.85;
        DDLogInfo(@"Using a default avg step length: %.3f m.", self.averageStepLength);
    }

}

@end