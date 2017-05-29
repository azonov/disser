//
// Created by Yaroslav Vorontsov on 29.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import DZNEmptyDataSet;

#import "WCBeaconListViewController.h"
#import "WCDiscoveryManager.h"
#import "Main.storyboard.h"
#import "WCListDataSource.h"
#import "HardwareDescription.h"
#import "UIViewController+Additions.h"
#import "WCBeaconDetailsViewController.h"
#import "HardwareInfo.h"
#import "WCPeripheralConnection.h"
#import "WCTableViewCell.h"
#import "WCPeripheralSelectionInteractor.h"

@interface WCBeaconListViewController() <UITableViewDelegate, DZNEmptyDataSetDelegate, WCPeripheralInteractionDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) UIRefreshControl *refreshControl;

@property (strong, nonatomic, readwrite) id<WCDiscoveryManager> discoveryService;
@property (strong, nonatomic, readonly) WCPeripheralSelectionInteractor *interactor;
@property (strong, nonatomic, readonly) WCListDataSource *dataSource;
@end

@implementation WCBeaconListViewController
{
    WCListDataSource *_dataSource;
    WCPeripheralSelectionInteractor *_interactor;
}

#pragma mark - Overridden getters/setters

- (NSAttributedString *)emptyDataSetTitle
{
    return [[NSAttributedString alloc] initWithString:@"No beacons ranged"
                                           attributes:[WCListDataSource titleAttributes]];
}

- (NSAttributedString *)emptyDataSetDescription
{
    return [[NSAttributedString alloc] initWithString:@"Pull the table to start ranging"
                                           attributes:[WCListDataSource descriptionAttributes]];
}

- (WCListDataSource *)dataSource
{
    if (!_dataSource) {
        _dataSource = [[[[WCListDataSource alloc] initWithTableView:self.tableView]
                configureWithCellType:[WCTableViewCell class]]
                addCellConfigurationBlock:^(__kindof UITableViewCell *cell, id<WCPeripheralConnection> connection) {
                    cell.textLabel.text = connection.deviceName;
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"RSSI %zd dB", connection.rssi];
                }];
        _dataSource.emptyTitle = self.emptyDataSetTitle;
        _dataSource.emptyDescription = self.emptyDataSetDescription;
    }
    return _dataSource;
}

- (WCPeripheralSelectionInteractor *)interactor
{
    if (!_interactor) {
        _interactor = [[[WCPeripheralSelectionInteractor alloc] initWithDiscoveryService:self.discoveryService]
                bindToDataSource:self.dataSource];
        _interactor.delegate = self;
    }
    return _interactor;
}

#pragma mark - UI configuration

- (void)setTableView:(UITableView *)tableView
{
    if (_tableView != tableView) {
        _tableView = tableView;
        // Add refresh control
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshControlStarted:) forControlEvents:UIControlEventValueChanged];
        [_tableView addSubview:refreshControl];
        self.refreshControl = refreshControl;
        // Configure empty data set definitions
        _tableView.emptyDataSetDelegate = self;
        _tableView.tableFooterView = [UIView new];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.dataSource reloadEmptyDataSet];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.tableView.indexPathForSelectedRow != nil) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

#pragma mark - Actions

- (void)refreshControlStarted:(UIRefreshControl *)sender
{
    if (self.interactor.rangingEnabled) {
        [sender endRefreshing];
    } else {
        [self.interactor startDiscoveryForHardware:self.hardware];
    }
}

#pragma mark - Peripheral interaction delegate

- (void)interactorDidConnectToPeripheral:(WCPeripheralSelectionInteractor *)interactor
{
    [self.refreshControl endRefreshing];
}

- (void)interactorDidDisconnectFromPeripheral:(WCPeripheralSelectionInteractor *)interactor
{

}


#pragma mark - DZNEmptyDataSetDelegate implementation

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

#pragma mark - UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<WCPeripheralConnection> connection = self.dataSource.items[(NSUInteger) indexPath.row];
    [self performSegueWithIdentifier:BeaconListSegues.toBeaconDetails configurationBlock:^(UIStoryboardSegue *segue) {
        WCBeaconDetailsViewController *detailsViewController = segue.destinationViewController;
        detailsViewController.connection = connection;
    }];
}

#pragma mark - Routing

- (IBAction)unwindToBeaconList:(UIStoryboardSegue *)sender
{
}

@end