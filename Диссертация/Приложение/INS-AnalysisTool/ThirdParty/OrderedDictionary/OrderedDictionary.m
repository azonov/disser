//
//  OrderedDictionary.m
//  OrderedDictionary
//
//  Created by Matt Gallagher on 19/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import "OrderedDictionary.h"

#pragma mark - Implementation of immutable version of dictionary

@implementation OrderedDictionary
{
    NSArray *_orderedKeys;
    NSDictionary *_innerDictionary;
}

#pragma mark - Initialization

- (instancetype)init
{
    if ((self = [super init])) {
        _orderedKeys = @[];
        _innerDictionary = @{};
    }
    return self;
}

- (instancetype)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys
{
    if ((self = [super init])) {
        _orderedKeys = keys;
        _innerDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    }
    return self;
}

- (instancetype)initWithObjects:(const id __nonnull [])objects
                        forKeys:(const id<NSCopying> __nonnull [])keys
                          count:(NSUInteger)cnt
{
    if ((self = [super init])) {
        _orderedKeys = [NSArray arrayWithObjects:objects count:cnt];
        _innerDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys count:cnt];
    }
    return self;
}

- (instancetype)initWithObjectsAndKeys:(id)firstObject, ...
{
    NSAssert(NO, @"This method is not supported for an ordered dictionary");
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary
{
    NSAssert(NO, @"This method is not supported for an ordered dictionary");
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary copyItems:(BOOL)flag
{
    NSAssert(NO, @"This method is not supported for an ordered dictionary");
    return self;
}

#pragma mark - Properties

- (NSUInteger)count
{
    return _orderedKeys.count;
}

- (id)objectForKey:(id)aKey
{
    return _innerDictionary[aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return _orderedKeys.objectEnumerator;
}

#pragma mark - Keys/Values collection

- (NSArray *)allKeys
{
    return _orderedKeys;
}

- (NSArray *)allValues
{
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:self.count];
    for (id key in self.allKeys) {
        [values addObject:self[key]];
    }
    return values;
}

#pragma mark - Copying

- (id)copy
{
    return [[OrderedDictionary alloc] initWithObjects:self.allValues forKeys:self.allKeys];
}

- (id)mutableCopy
{
    return [[MutableOrderedDictionary alloc] initWithObjects:self.allValues forKeys:self.allKeys];
}

#pragma mark - Implementation of the protocol

- (NSUInteger)indexOfObjectWithKey:(id)key
{
    return [_orderedKeys indexOfObject:key];
}

@end

#pragma mark - Implementation of mutable version of dictionary

@implementation MutableOrderedDictionary
{
    NSMutableArray *_orderedKeys;
    NSMutableDictionary *_innerDictionary;
}

#pragma mark - Initialization

- (instancetype)init
{
    if ((self = [super init])) {
        _innerDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
        _orderedKeys = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity
{
    if ((self = [super init])) {
        _innerDictionary = [NSMutableDictionary dictionaryWithCapacity:capacity];
        _orderedKeys = [NSMutableArray arrayWithCapacity:capacity];
    }
    return self;
}

#pragma mark - NSMutableDictionary's overridden methods

- (void)setObject:(id)anObject forKey:(id)aKey
{
    if (!_innerDictionary[aKey]) {
        [_orderedKeys addObject:aKey];
    }
    _innerDictionary[aKey] = anObject;
}

- (void)removeObjectForKey:(id)aKey
{
    [_innerDictionary removeObjectForKey:aKey];
    [_orderedKeys removeObject:aKey];
}

#pragma mark - Keys/Values collection

- (NSArray *)allKeys
{
    return _orderedKeys;
}

- (NSArray *)allValues
{
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:self.count];
    for (id key in self.allKeys) {
        [values addObject:self[key]];
    }
    return values;
}

#pragma mark - Copying

- (id)copy
{
    return [[OrderedDictionary alloc] initWithObjects:self.allValues forKeys:self.allKeys];
}

- (id)mutableCopy
{
    return [[MutableOrderedDictionary alloc] initWithObjects:self.allValues forKeys:self.allKeys];
}

#pragma mark - Implementation of the protocol

- (NSUInteger)indexOfObjectWithKey:(id)key
{
    return [_orderedKeys indexOfObject:key];
}

- (void)removeObjectAndKeyAtIndex:(NSUInteger)index
{
    [self removeObjectForKey:_orderedKeys[index]];
}

@end