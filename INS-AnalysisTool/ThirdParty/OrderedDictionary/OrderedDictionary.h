//
//  OrderedDictionary.h
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


// Idea taken from here:
// http://www.cocoawithlove.com/2008/12/ordereddictionary-subclassing-cocoa.html
// ARC-ified by Yaroslav Vorontsov, 12/08/2014
// Immutable implementation added by Yaroslav Vorontsov, 18/08/2016

@import Foundation;

/**
 *
 * The following methods and properties should be implemented for a successor of NSDictionary
 *
 * @property (readonly) NSUInteger count;
 * - (nullable ObjectType)objectForKey:(KeyType)aKey;
 * - (NSEnumerator<KeyType> *)keyEnumerator;
 * - (instancetype)initWithObjects:(const ObjectType [])objects forKeys:(const KeyType <NSCopying> [])keys count:(NSUInteger)cnt NS_DESIGNATED_INITIALIZER;
 * - (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
 */

@protocol OrderedKeyedCollection <NSObject>
- (NSUInteger)indexOfObjectWithKey:(id)key;
@end

@protocol MutableOrderedKeyedCollection <OrderedKeyedCollection>
- (void)removeObjectAndKeyAtIndex:(NSUInteger)index;
@end

@interface OrderedDictionary<KeyType, ObjectType>: NSDictionary<KeyType, ObjectType> <OrderedKeyedCollection>
@end

@interface MutableOrderedDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType> <MutableOrderedKeyedCollection>
@end