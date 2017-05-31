//
//  MEPulsingHaloLayer.h
//  https://github.com/shu223/PulsingHalo
//
//  Created by shuichi on 12/5/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//
//  Inspired by https://github.com/samvermette/SVPulsingAnnotationView

/**
* Partially modified by Yaroslav Vorontsov
* Copyright (c) 2015 Yaroslav Vorontsov
*/


@import QuartzCore;
@import UIKit;


@interface MEPulsingHaloLayer : CALayer

@property (nonatomic, assign) CGFloat radius;                   // default: 60pt
@property (nonatomic, assign) CGFloat fromValueForRadius;       // default: 0.0
@property (nonatomic, assign) CGFloat fromValueForAlpha;        // default: 0.45
@property (nonatomic, assign) CGFloat keyTimeForHalfOpacity;    // default: 0.2 (range: 0 < keyTime < 1)
@property (nonatomic, assign) NSTimeInterval animationDuration; // default: 3s
@property (nonatomic, assign) NSTimeInterval pulseInterval;     // default: 0s
@property (atomic, assign) float repeatCount;                // default: INFINITY
@property (nonatomic, assign) BOOL useTimingFunction;           // default: YES should use timingFunction for animation

- (id)initWithRepeatCount:(float)repeatCount;
- (void)pauseAnimation;
- (void)resumeAnimation;

@end
