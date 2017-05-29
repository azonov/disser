//
// Created by Yaroslav Vorontsov on 03.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import UIKit;

typedef void (^SegueConfigurationBlock)(UIStoryboardSegue *);


@interface UIViewController (Additions)
// Convenient for unwind segues or segues which do not require any kind of configuration
- (void)performSegueWithIdentifier:(NSString *)identifier;
// Convenient for segues which do not require an explicit declaration of sender
- (void)performSegueWithIdentifier:(NSString *)identifier configurationBlock:(SegueConfigurationBlock)block;
- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender configurationBlock:(SegueConfigurationBlock)block;
@end
