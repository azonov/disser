//
// Created by Yaroslav Vorontsov on 17.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCTableViewCell.h"


@implementation WCTableViewCell
{

}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) {
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}


@end