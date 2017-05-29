//
// Created by Yaroslav Vorontsov on 24.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import "MEPulsingPointLayer.h"
#import "MEPulsingHaloLayer.h"


@implementation MEPulsingPointLayer
{

}

#pragma mark - Initialization

- (instancetype)initWithPointColor:(UIColor *)pointColor
                        pulseColor:(UIColor *)pulseColor
                       pulseRadius:(CGFloat)pulseRadius
                       pointRadius:(CGFloat)pointRadius
{
    if ((self = [super init])) {

        self.frame = (CGRect){CGPointZero, CGSizeMake(2 * pulseRadius, 2 * pulseRadius)};

        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.frame = (CGRect){CGPointZero, CGSizeMake(2 * pointRadius, 2 * pointRadius)};
        shapeLayer.position = CGPointMake(pulseRadius, pulseRadius);
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(pointRadius, pointRadius)
                                                            radius:pointRadius
                                                        startAngle:0.0f
                                                          endAngle:(CGFloat) (M_PI * 2.0f)
                                                         clockwise:YES];
        shapeLayer.fillColor = pointColor.CGColor;
        shapeLayer.path = path.CGPath;

        MEPulsingHaloLayer *haloLayer = [[MEPulsingHaloLayer alloc] init];
        haloLayer.position = shapeLayer.position;
        haloLayer.backgroundColor = pulseColor.CGColor;
        haloLayer.radius = pulseRadius;

        [self addSublayer:haloLayer];
        [self addSublayer:shapeLayer];
        _haloLayer = haloLayer;
        _pointLayer = shapeLayer;
    }
    return self;
}


#pragma mark - Factory methods

+ (instancetype)userLocationLayer
{
    return [[self alloc] initWithPointColor:[UIColor greenColor]
                                 pulseColor:[UIColor yellowColor]
                                pulseRadius:40.0f
                                pointRadius:5.0f];
}

+ (instancetype)userMotionLayer
{
    return [[self alloc] initWithPointColor:[UIColor redColor]
                                 pulseColor:[UIColor yellowColor]
                                pulseRadius:40.0f
                                pointRadius:5.0f];
}

+ (instancetype)beaconLocationLayer
{
    return [[self alloc] initWithPointColor:[UIColor blueColor]
                                 pulseColor:[UIColor purpleColor]
                                pulseRadius:60.0f
                                pointRadius:5.0f];
}

#pragma mark - Chain of responsibility - pass to pulsing layer

- (void)pauseAnimation
{
    [self.haloLayer pauseAnimation];
}

- (void)resumeAnimation
{
    [self.haloLayer resumeAnimation];
}


@end