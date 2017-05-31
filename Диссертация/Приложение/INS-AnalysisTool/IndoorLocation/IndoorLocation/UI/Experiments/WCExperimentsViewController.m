//
//  ViewController.m
//  WellcoreCalibrator
//
//  Created by Yaroslav Vorontsov on 30.05.16.
//  Copyright © 2016 DataArt. All rights reserved.
//

#import "WCExperimentsViewController.h"
#import "WCCSVDataGrabber.h"
#import "WCBeaconRanger.h"
#import "WCSensorFusion.h"

@interface WCExperimentsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *rangingTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;

@property (strong, nonatomic, readwrite) CLBeaconRegion *rangedRegion;
@property (strong, nonatomic, readwrite) id<WCBeaconRanger> rangingService;
@property (strong, nonatomic, readwrite) id<WCCSVDataGrabber> csvGrabber;
@property (strong, nonatomic, readwrite) id<WCSensorFusion> sensorService;

@property (assign, nonatomic) NSUInteger counter;
@property (assign, nonatomic) BOOL recording;
@end

@implementation WCExperimentsViewController


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(measurementCompleted:)
                   name:WCBeaconRangerNotifications.beaconsRanged
                 object:self.rangingService];
    [center addObserver:self
               selector:@selector(measurementCompleted:)
                   name:WCSensorFusionNotifications.measurementCompleted
                 object:self.sensorService];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Starting and stopping recording

- (void)startRecordingForExperiment:(NSInteger)index intoFile:(NSString *)file
{
    self.counter = 0;
    self.csvGrabber.fileName = file;
    self.fileNameLabel.text = [NSString stringWithFormat:@"Writing into file ~/Documents/%@.csv", file];
    self.rangingTimeLabel.text = @" ";
    [self startExperimentWithIndex:index];
}

- (void)stopRecordingForExperiment:(NSInteger)index
{
    [self stopExperimentWithIndex:index];
    [self.csvGrabber flushLogs];
    self.fileNameLabel.text = [NSString stringWithFormat:@"File saved: ~/Documents/%@.csv", self.csvGrabber.fileName];
}

#pragma mark - Handling ranging events

- (void)measurementCompleted:(NSNotification *)notification
{
    ++self.counter;
    self.rangingTimeLabel.text = [NSString stringWithFormat:@"Time elapsed: %tu s", self.counter];
}

#pragma mark - Alert controller factory method

- (UIViewController *)alertControllerForExperiment:(NSInteger)index
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Information"
                                                                             message:@"Please enter the name of experiment"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = self.csvGrabber.fileName;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self startRecordingForExperiment:index intoFile:alertController.textFields.firstObject.text];
    }]];
    return alertController;
}

#pragma mark - Action handlers

- (IBAction)experimentButtonTapped:(UIButton *)button
{
    if (self.recording) {
        [self stopRecordingForExperiment:button.tag];
    } else {
        [self presentViewController:[self alertControllerForExperiment:button.tag] animated:YES completion:nil];
    }
    button.selected = (self.recording = !self.recording);
}

#pragma mark - Experiment actions

- (void)startExperimentWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            [self.rangingService startTrackingRegion:self.rangedRegion];
            break;
        case 1:
            [self.sensorService startGatheringSensorData];
            break;
        case 2:
            [self.rangingService startTrackingRegion:self.rangedRegion];
            [self.sensorService startGatheringSensorData];
            break;
        default:
            break;
    }
}

- (void)stopExperimentWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            [self.rangingService stopTrackingRegion:self.rangedRegion];
            break;
        case 1:
            [self.sensorService stopGatheringSensorData];
            break;
        case 2:
            [self.rangingService stopTrackingRegion:self.rangedRegion];
            [self.sensorService stopGatheringSensorData];
            break;
        default:
            break;
    }
}

@end
