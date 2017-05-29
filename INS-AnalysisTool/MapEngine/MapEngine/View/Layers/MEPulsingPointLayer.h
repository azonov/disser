//
// Created by Yaroslav Vorontsov on 24.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

@import UIKit;
@import QuartzCore;
@class MEPulsingHaloLayer;


@interface MEPulsingPointLayer : CALayer
@property (weak, nonatomic, readonly) MEPulsingHaloLayer *haloLayer;
@property (weak, nonatomic, readonly) CAShapeLayer *pointLayer;
@property (assign, nonatomic) NSInteger index;
- (instancetype)initWithPointColor:(UIColor *)pointColor
                        pulseColor:(UIColor *)pulseColor
                       pulseRadius:(CGFloat)pulseRadius
                       pointRadius:(CGFloat)pointRadius;
+ (instancetype)userLocationLayer;
+ (instancetype)userMotionLayer;
+ (instancetype)beaconLocationLayer;
- (void)pauseAnimation;
- (void)resumeAnimation;
@end