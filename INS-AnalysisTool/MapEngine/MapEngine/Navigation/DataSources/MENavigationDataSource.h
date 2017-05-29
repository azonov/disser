//
// Created by Yaroslav Vorontsov on 17.10.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MEMapBundle;
typedef void (^MENavigationDataSourceListenerBlock)(NSString *identifier, NSValue *value);

@protocol MENavigationDataSource <NSObject>
@property(copy, nonatomic, readonly) NSString *identifier;
- (instancetype)addListener:(MENavigationDataSourceListenerBlock)block;
- (void)startTrackingOnMap:(MEMapBundle *)mapBundle;
- (void)stopTrackingOnMap:(MEMapBundle *)mapBundle;
@end