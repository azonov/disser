//
// Created by Yaroslav Vorontsov on 01.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
#import "WCInteractor.h"
#import "ILConstants.h"

@interface WCHardwareSelectionInteractor : WCInteractor
@property (strong, nonatomic, readonly) NSArray *__nullable models;
- (void)fetchHardwareWithCompletion:(__nonnull SimpleBlock)block;
@end