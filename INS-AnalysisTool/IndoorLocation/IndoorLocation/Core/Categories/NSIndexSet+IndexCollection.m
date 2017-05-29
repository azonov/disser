//
// Created by Yaroslav Vorontsov on 18.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "NSIndexSet+IndexCollection.h"


@implementation NSIndexSet (IndexCollection)

- (NSArray *)indexCollection
{
    NSMutableArray *indexes = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexes addObject:@(idx)];
    }];
    return [indexes copy];
}


@end