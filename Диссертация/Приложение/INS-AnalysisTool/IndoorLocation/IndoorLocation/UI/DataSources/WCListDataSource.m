//
// Created by Yaroslav Vorontsov on 29.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCListDataSource.h"
#import "NSIndexSet+IndexCollection.h"
#import "CollectionUtils.h"


#pragma mark - Additional declarations

@interface WCListDataSource()
@property (weak, nonatomic, readonly) UITableView *tableView;
@property (copy, nonatomic, readonly) CellConfigurationBlock configurationBlock;
@property (copy, nonatomic, readonly) NSString *reuseIdentifier;
@end


@implementation WCListDataSource
{
    UIActivityIndicatorView *_activityIndicator;
    NSMutableArray *_items;
}

#pragma mark - Initialization

- (instancetype)initWithTableView:(UITableView *__nonnull)tableView
{
    if ((self = [super init])) {
        _tableView = tableView;
        _tableView.dataSource = self;
        _tableView.emptyDataSetSource = self;
        // Setting default values
        _configurationBlock = ^(__kindof UITableViewCell *cell, id o) { };
        _reuseIdentifier = NSStringFromClass([UITableViewCell class]);
        _rowAnimation = UITableViewRowAnimationAutomatic;
    }
    return self;
}

#pragma mark - Configuration

- (instancetype)configureWithCellType:(Class <WCReusableItem> __nonnull)cellType
{
    id typeObj = cellType; // to silence compiler's warnings
    NSParameterAssert([typeObj conformsToProtocol:@protocol(WCReusableItem)]);
    _reuseIdentifier = [cellType reuseIdentifier];
    if ([typeObj conformsToProtocol:@protocol(WCNibReusableItem)]) {
        [self.tableView registerNib:[typeObj nib] forCellReuseIdentifier:self.reuseIdentifier];
    } else {
        [self.tableView registerClass:cellType forCellReuseIdentifier:self.reuseIdentifier];
    }
    return self;
}

- (instancetype)addCellConfigurationBlock:(__nonnull CellConfigurationBlock)block
{
    NSParameterAssert(block != nil);
    _configurationBlock = [block copy];
    return self;
}

#pragma mark - Overridden getters/setters

- (UIActivityIndicatorView *)activityIndicator
{
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.color = [UIColor darkGrayColor];
    }
    return _activityIndicator;
}

- (NSArray *)items
{
    if (!_items) {
        _items = [NSMutableArray array];
    }
    return [_items copy];
}

- (void)setItems:(NSArray *)items
{
    if (_items != items) {
        _items = [items mutableCopy];
        [self.tableView reloadData];
        if (items.count == 0) {
            [self.tableView reloadEmptyDataSet];
        }
    }
}

#pragma mark - Data set management

- (void)reloadEmptyDataSet
{
    [self.tableView reloadEmptyDataSet];
}

- (void)appendItem:(id)item
{
    NSParameterAssert(item != nil);
    NSInteger rowIndex = self.items.count;
    [self.tableView beginUpdates];
    [_items addObject:item];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:self.rowAnimation];
    [self.tableView endUpdates];
}

- (void)reloadItemsAtIndexes:(NSIndexSet *)indexes
{
    [self.tableView beginUpdates];
    NSArray *indexPaths = [indexes.indexCollection map:^id(NSNumber *idx) {
        return [NSIndexPath indexPathForRow:idx.integerValue inSection:0];
    }];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    [self.tableView endUpdates];
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes
{
    [self.tableView beginUpdates];
    [_items removeObjectsAtIndexes:indexes];
    NSArray *indexPaths = [indexes.indexCollection map:^id(NSNumber *idx) {
        return [NSIndexPath indexPathForRow:idx.integerValue inSection:0];
    }];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:self.rowAnimation];
    [self.tableView endUpdates];
}

#pragma mark - UITableViewDataSource implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __kindof UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier forIndexPath:indexPath];
    __kindof id item = self.items[(NSUInteger) indexPath.row];
    self.configurationBlock(cell, item);
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - DZNEmptyDataSource implementation

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    return self.emptyTitle;
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    return self.emptyDescription;
}

- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView
{
    return self.useActivityIndicator? self.activityIndicator : nil;
}

@end

#pragma mark - Styles as a category

@implementation WCListDataSource(Styles)

+ (NSDictionary *__nonnull)titleAttributes
{
    return @{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:20.0f],
            NSForegroundColorAttributeName: [UIColor darkGrayColor]
    };
}

+ (NSDictionary *__nonnull)descriptionAttributes
{
    return @{
            NSFontAttributeName: [UIFont italicSystemFontOfSize:15.0f],
            NSForegroundColorAttributeName: [UIColor lightGrayColor]
    };
}


@end