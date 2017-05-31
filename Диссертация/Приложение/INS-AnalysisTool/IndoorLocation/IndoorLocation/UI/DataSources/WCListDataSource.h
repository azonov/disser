//
// Created by Yaroslav Vorontsov on 29.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

/**
 * I've searched for existing implementations of table view data sources. Here are they:
 *
 * Nimbus
 * https://github.com/jverkoey/nimbus/tree/master/src/models/src
 * http://www.slideshare.net/Rambler-iOS/nimbus-models
 *
 * SSDataSources
 * https://github.com/splinesoft/SSDataSources
 *
 * Both seems to be abandoned :(
 */

@import UIKit;
@import DZNEmptyDataSet;

@protocol WCReusableItem <NSObject>
+ (NSString *__nonnull) reuseIdentifier;
@end

@protocol WCNibReusableItem <WCReusableItem>
+ (UINib *__nullable)nib;
@end

// Implementation of a refreshable data source

@interface WCListDataSource: NSObject <UITableViewDataSource, DZNEmptyDataSetSource>
// Generic type definition within a class
typedef void (^CellConfigurationBlock)( __kindof UITableViewCell * __nonnull, __nonnull id);
// Configurable items
@property (strong, nonatomic) NSArray * __nullable items;
// Empty data set configuration
@property (strong, nonatomic) NSAttributedString *__nullable emptyTitle;
@property (strong, nonatomic) NSAttributedString *__nullable emptyDescription;
// Activity indicators and other appearance methods
@property (strong, nonatomic, readonly) UIActivityIndicatorView *__nonnull activityIndicator;
@property (assign, nonatomic) UITableViewRowAnimation rowAnimation;
@property (assign, nonatomic) BOOL useActivityIndicator;
- (__nullable instancetype)initWithTableView:(UITableView * __nonnull)tableView;
- (__nonnull instancetype)configureWithCellType:(Class<WCReusableItem> __nonnull)cellType;
- (__nonnull instancetype)addCellConfigurationBlock:(CellConfigurationBlock __nonnull)block;
- (void)reloadEmptyDataSet;
- (void)appendItem:(__nonnull id)item;
- (void)reloadItemsAtIndexes:(NSIndexSet *__nonnull)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *__nonnull)indexes;
@end

@interface WCListDataSource(Styles)
+ (NSDictionary  *__nonnull)titleAttributes;
+ (NSDictionary *__nonnull)descriptionAttributes;
@end