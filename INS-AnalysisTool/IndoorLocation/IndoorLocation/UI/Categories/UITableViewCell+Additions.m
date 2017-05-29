//
// Created by Yaroslav Vorontsov on 02.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "UITableViewCell+Additions.h"

@implementation UITableViewCell (Additions)

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass(self);
}

+ (UINib *)nib
{
    // Will crash for UITableViewCell, will work for all cells defined in XIBs
    return [UINib nibWithNibName:[self reuseIdentifier] bundle:[NSBundle bundleForClass:self]];
}

@end