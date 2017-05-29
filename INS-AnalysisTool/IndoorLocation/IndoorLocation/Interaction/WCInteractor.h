//
// Created by Yaroslav Vorontsov on 01.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;


@interface WCInteractor : NSObject
@property (strong, nonatomic, readonly) NSOperationQueue *workQueue;
@property (strong, nonatomic, readonly) NSOperationQueue *callbackQueue;
+ (NSOperationQueue *)defaultWorkQueue;
- (instancetype)initWithWorkQueue:(NSOperationQueue *)workQueue callbackQueue:(NSOperationQueue *)callbackQueue;
@end