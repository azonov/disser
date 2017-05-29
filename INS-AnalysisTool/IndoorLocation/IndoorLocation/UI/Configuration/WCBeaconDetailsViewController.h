//
// Created by Yaroslav Vorontsov on 29.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import UIKit;
@import XLForm;
@import SVProgressHUD;

@protocol WCPeripheralConnection;

@interface WCBeaconDetailsViewController : XLFormViewController
@property (strong, nonatomic) id<WCPeripheralConnection> connection;
@end