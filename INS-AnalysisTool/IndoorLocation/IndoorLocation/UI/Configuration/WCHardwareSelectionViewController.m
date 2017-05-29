//
// Created by Yaroslav Vorontsov on 01.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import libextobjc;

#import "WCHardwareSelectionViewController.h"
#import "WCHardwareSelectionInteractor.h"
#import "WCListDataSource.h"
#import "HardwareDescription.h"
#import "Main.storyboard.h"
#import "UIViewController+Additions.h"
#import "WCBeaconListViewController.h"
#import "WCTableViewCell.h"

@interface WCHardwareSelectionViewController() <UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic, readonly) WCHardwareSelectionInteractor *interactor;
@property (strong, nonatomic, readonly) WCListDataSource *dataSource;
@end


@implementation WCHardwareSelectionViewController
{
    WCHardwareSelectionInteractor *_interactor;
    WCListDataSource *_dataSource;
}

#pragma mark - Overridden getters/setters

- (WCHardwareSelectionInteractor *)interactor
{
    if (!_interactor) {
        _interactor = [WCHardwareSelectionInteractor new];
    }
    return _interactor;
}

- (WCListDataSource *)dataSource
{
    if (!_dataSource) {
        _dataSource = [[[[WCListDataSource alloc] initWithTableView:self.tableView]
                configureWithCellType:[WCTableViewCell class]]
                addCellConfigurationBlock:^(__kindof UITableViewCell *cell, id<HardwareInfo> info) {
                    cell.textLabel.text = info.name;
                }];
        _dataSource.emptyTitle = self.emptyDataSetTitle;
        _dataSource.emptyDescription = self.emptyDataSetDescription;
        _dataSource.useActivityIndicator = YES;
    }
    return _dataSource;
}

- (NSAttributedString *)emptyDataSetTitle
{
    return [[NSAttributedString alloc] initWithString:@"No hardware available yet"
                                           attributes:[WCListDataSource titleAttributes]];
}

- (NSAttributedString *)emptyDataSetDescription
{
    return [[NSAttributedString alloc] initWithString:@"Update your app with a new XML file with the hardware specs"
                                           attributes:[WCListDataSource descriptionAttributes]];
}

#pragma mark - UI configuration

- (void)setTableView:(UITableView *)tableView
{
    if (_tableView != tableView) {
        _tableView = tableView;
        // Configuring table view
        self.tableView.tableFooterView = [UIView new];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Fetch hardware, as desired
    @weakify(self);
    [self.dataSource.activityIndicator startAnimating];
    [self.interactor fetchHardwareWithCompletion:^{
        @strongify(self);
        [self.dataSource.activityIndicator stopAnimating];
        self.dataSource.items = self.interactor.models;
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.tableView.indexPathForSelectedRow != nil) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

#pragma mark - UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<HardwareInfo> info = self.dataSource.items[(NSUInteger) indexPath.row];
    [self performSegueWithIdentifier:HardwareSelectionSegues.toBeaconList configurationBlock:^(UIStoryboardSegue *segue) {
        WCBeaconListViewController *viewController = segue.destinationViewController;
        viewController.hardware = info;
    }];
}

@end