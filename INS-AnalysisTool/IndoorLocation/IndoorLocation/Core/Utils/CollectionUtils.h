//
// Created by Yaroslav Vorontsov on 01.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;


typedef __nonnull id (^MapBlock)(__nonnull id);
typedef __nonnull id (^MapWithKeyBlock)(__nonnull id, __nonnull id);

@interface NSArray (Additions)
- (__nonnull instancetype)map:(__nonnull MapBlock)block;
@end

@interface NSDictionary (Additions)
- (__nonnull instancetype)map:(__nonnull MapBlock)block;
- (__nonnull instancetype)keyedMap:(__nonnull MapWithKeyBlock)block;
@end