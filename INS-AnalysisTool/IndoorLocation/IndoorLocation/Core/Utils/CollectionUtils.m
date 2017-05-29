//
// Created by Yaroslav Vorontsov on 01.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "CollectionUtils.h"


@implementation NSArray (Additions)

- (instancetype)map:(MapBlock)block
{
    NSMutableArray *mappedValues = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [mappedValues addObject:block(obj)];
    }];
    return [mappedValues copy];
}

@end

@implementation NSDictionary (Additions)

- (instancetype)map:(MapBlock)block
{
    NSMutableDictionary *mappedValues = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        mappedValues[key] = block(obj);
    }];
    return [mappedValues copy];
}

- (instancetype)keyedMap:(__nonnull MapWithKeyBlock)block
{
    NSMutableDictionary *mappedValues = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        mappedValues[key] = block(key, obj);
    }];
    return [mappedValues copy];
}


@end