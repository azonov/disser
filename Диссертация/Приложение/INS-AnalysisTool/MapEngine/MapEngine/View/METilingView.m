/*
     File: TilingView.m
 Abstract: The main view controller for this application.
  Version: 1.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

/**
* Portions of code are taken from JCTiledScrollView library
* https://github.com/jessedc/JCTiledScrollView
* Copyright (c) 2012, Jesse Collis JC Multimedia Design. <jesse@jcmultimedia.com.au>
* All rights reserved.
*/

/**
* Portions of code modified and written by Yaroslav Vorontsov
* Copyright (C) 2015 Yaroslav Vorontsov
*/

@import CocoaLumberjack;
#import "METilingView.h"
#import "MEMapBundle.h"
#import "MEPulsingHaloLayer.h"
#import "MEMapBeacon.h"
#import "MEPulsingPointLayer.h"
#import "MEConstants.h"

/**
* This view includes Apple's Photo scroller sample code and JCTiledScrollView code from Github.
*
* Here's a link to the documentation about CATiledLayer
* https://developer.apple.com/library/prerelease/ios/documentation/GraphicsImaging/Reference/CATiledLayer_class/index.html#//apple_ref/occ/instp/CATiledLayer/
*
* CATiledLayer Cocoaheads talk (Melbourne)
* https://github.com/jessedc/JCTiledScrollView/blob/master/Cocoheads/talk_outline.md
*/


@interface METilingView ()
@property (strong, nonatomic, readonly) MEMapBundle *mapBundle;
@property (strong, nonatomic, readonly) CATiledLayer *tiledLayer;
@property (strong, nonatomic, readonly) NSSet *pulsars;
@property (strong, nonatomic, readonly) MEPulsingPointLayer *userLocationLayer;
@property (strong, nonatomic, readonly) CALayer *beaconsLayer;
@end

@implementation METilingView
{
    NSSet *_pulsars;
    CALayer *_beaconsLayer;
    MEPulsingPointLayer *_userLocationLayer;
}

#pragma mark - Initialization

- (instancetype)initWithMapBundle:(MEMapBundle *)mapBundle
{
    if ((self = [super initWithFrame:(CGRect){CGPointZero, mapBundle.imageSize}]))
    {
        self.tiledLayer.tileSize = [mapBundle tileSizeForScale:self.contentScaleFactor];
        self.tiledLayer.levelsOfDetail = 0;
        self.tiledLayer.levelsOfDetailBias = mapBundle.levelsOfDetails;
        _mapBundle = mapBundle;
        self.showsBeacons = NO;
        self.showsUserLocation = NO;
        self.pulseRadius = 30.0f;
        self.zoomScale = 1;
        DDLogDebug(@"Loaded map %@ from bundle. Size is %@ / scale factor %f", mapBundle.name, NSStringFromCGSize(mapBundle.imageSize), self.contentScaleFactor);
    }
    return self;
}

#pragma mark - Overridden properties

+ (Class)layerClass
{
    return [CATiledLayer class];
}

#pragma mark - Getters and setters

- (CATiledLayer *)tiledLayer
{
    return (CATiledLayer *) self.layer;
}

- (MEPulsingPointLayer *)userLocationLayer
{
    if (!_userLocationLayer) {
        _userLocationLayer = [MEPulsingPointLayer userLocationLayer];
        _userLocationLayer.hidden = YES;
        _userLocationLayer.index = -1;
    }
    return _userLocationLayer;
}

- (CALayer *)beaconsLayer
{
    if (!_beaconsLayer) {
        _beaconsLayer = [[CALayer alloc] init];
        _beaconsLayer.frame = (CGRect){CGPointZero, self.mapBundle.imageSize};
        for (MEMapBeacon *item in self.mapBundle.beacons) {
            MEPulsingPointLayer *beaconLayer = [MEPulsingPointLayer beaconLocationLayer];
            beaconLayer.position = CGPointMake((CGFloat) (item.coordinate.x / self.mapBundle.maxScale),
                    (CGFloat) (item.coordinate.y / self.mapBundle.maxScale));
            beaconLayer.index = item.minor;
            beaconLayer.hidden = YES;
            [_beaconsLayer addSublayer:beaconLayer];
        }
    }
    return _beaconsLayer;
}

- (NSSet *)pulsars
{
    if (!_pulsars) {
        NSArray *extraPulsars = @[self.userLocationLayer];
        _pulsars = [NSSet setWithArray:[self.beaconsLayer.sublayers arrayByAddingObjectsFromArray:extraPulsars]];
    }
    return _pulsars;
}

- (void)setZoomScale:(CGFloat)zoomScale
{
    _zoomScale = zoomScale;
    CGFloat scaleFactor = 1 + log2f(zoomScale);
    CGFloat newRadius = self.pulseRadius / scaleFactor;
    [self.pulsars enumerateObjectsUsingBlock:^(MEPulsingPointLayer *obj, BOOL *stop) {
        obj.haloLayer.radius = newRadius;
        obj.pointLayer.transform = CATransform3DMakeScale(1 / scaleFactor, 1 / scaleFactor, 1);
    }];
}

- (void)setShowsBeacons:(BOOL)showsBeacons
{
    if (_showsBeacons != showsBeacons) {
        _showsBeacons = showsBeacons;
        if (showsBeacons) {
            [self.tiledLayer addSublayer:self.beaconsLayer];
        } else if (_beaconsLayer) {
            [self.beaconsLayer removeFromSuperlayer];
        }
    }
}

- (void)setShowsUserLocation:(BOOL)showsUserLocation
{
    if (_showsUserLocation != showsUserLocation) {
        _showsUserLocation = showsUserLocation;
        if (showsUserLocation) {
            [self.tiledLayer addSublayer:self.userLocationLayer];
        } else if (_userLocationLayer) {
            [self.userLocationLayer removeFromSuperlayer];
        }
    }
}

- (void)setUserLocation:(CGPoint)userLocation
{
    if (!CGPointEqualToPoint(_userLocation, userLocation)) {
        _userLocation = userLocation;
        self.userLocationLayer.hidden = NO;
        self.userLocationLayer.position = userLocation;
    }
}

- (void)setHighlightedBeacons:(NSSet *)highlightedBeacons
{
    if (_highlightedBeacons != highlightedBeacons) {
        _highlightedBeacons = highlightedBeacons;
        [self.pulsars enumerateObjectsUsingBlock:^(MEPulsingPointLayer *obj, BOOL *stop) {
            obj.hidden = obj.index > 0 && ![highlightedBeacons containsObject:@(obj.index)];
        }];
    }
}

#pragma mark - Animation management

- (void)cancelAnimations
{
    [self.pulsars makeObjectsPerformSelector:@selector(pauseAnimation)];
}

- (void)resumeAnimations
{
    [self.pulsars makeObjectsPerformSelector:@selector(resumeAnimation)];
}

#pragma mark - Content drawing

- (void)drawRect:(CGRect)rect
{
    // Here we get the scale from the context by getting the current transform matrix, then asking
    // for its "a" component, which is one of the two scale components. We could also ask for "d".
    // This assumes (safely) that the view is being scaled equally in both dimensions.
    // PLZ NOTE: This codee is different from that one used in Apple's PhotoScroller application and is inspired by
    // the JCTiledScrollView and its explanation
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat scale = CGContextGetCTM(context).a / self.layer.contentsScale;
    int col = (int)((CGRectGetMinX(rect) * scale) / self.mapBundle.tileSize.width);
    int row = (int)((CGRectGetMinY(rect) * scale) / self.mapBundle.tileSize.height);
    UIImage *tile = [self.mapBundle tileForScale:scale row:row col:col];
    [tile drawInRect:rect];
}


@end
