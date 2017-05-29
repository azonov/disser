//
// Created by Yaroslav Vorontsov on 17.04.15.
// Copyright (c) 2015 Yaroslav Vorontsov. All rights reserved.
//

#import "MapEngine.h"
#import "METilingView.h"
#import "MEGaussianTrilateration.h"


@interface METiledMapView ()
@property (strong, nonatomic, readonly) NSNotificationCenter *notificationCenter;
@property (strong, nonatomic, readonly) UIScrollView *scrollView;
@property (strong, nonatomic) METilingView *tilingView;
@property (strong, nonatomic, readonly) MENavigationManager *navigationManager;
@end

@implementation METiledMapView
{
    MENavigationManager *_navigationManager;
}

#pragma mark - Initialization and memory management

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder])) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _notificationCenter = [NSNotificationCenter defaultCenter];
    _trackUserLocation = NO;
    _showBeacons = NO;
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.delegate = self;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.bounces = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:self.scrollView];
}

- (void)dealloc
{
    self.scrollView.delegate = nil;
    [self.notificationCenter removeObserver:self];
}

#pragma mark - Getters and setters

- (MENavigationManager *)navigationManager
{
    if (!_navigationManager) {
        _navigationManager = [[MENavigationManager alloc] init];
        _navigationManager.trilaterationAlgorithm = [self trilaterationAlgorithm];
        [self.notificationCenter addObserver:self
                                    selector:@selector(locationUpdated:)
                                        name:MENavigationNotificationKeys.locationUpdatedNotification
                                      object:_navigationManager];
    }
    return _navigationManager;
}

- (void)setMapBundle:(MEMapBundle *)mapBundle
{
    if (self.trackUserLocation && _mapBundle) {
        [self.navigationManager stopTrackingOnMap:_mapBundle];
    }
    _mapBundle = mapBundle;
    if (self.trackUserLocation && mapBundle) {
        [self.navigationManager startTrackingOnMap:mapBundle];
    }
    [self displayTiledMap];
}

- (void)setTrackUserLocation:(BOOL)trackUserLocation
{
    if (trackUserLocation != _trackUserLocation) {
        _trackUserLocation = trackUserLocation;
        self.tilingView.showsUserLocation = trackUserLocation;
        if (self.mapBundle) {
            trackUserLocation
                    ? [self.navigationManager startTrackingOnMap:self.mapBundle]
                    : [self.navigationManager stopTrackingOnMap:self.mapBundle];
        }
    }
}

- (void)setShowBeacons:(BOOL)showBeacons
{
    if (_showBeacons != showBeacons) {
        _showBeacons = showBeacons;
        self.tilingView.showsBeacons = showBeacons;
    }
}

#pragma mark - Delegate methods

- (id<MEPositioningAlgorithm>)trilaterationAlgorithm
{
    return [self.delegate respondsToSelector:@selector(trilaterationAlgorithmForMap:)]
            ? [self.delegate trilaterationAlgorithmForMap:self]
            : [[MEGaussianTrilateration alloc] init];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self centerZoomingView];
}

- (void)centerZoomingView
{
    // center the zoom view as it becomes smaller/greater than the size of the screen
    CGRect frameToCenter = self.tilingView.frame;
    CGSize boundsSize = self.scrollView.bounds.size;
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    } else {
        frameToCenter.origin.x = 0;
    }

    // center vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    } else {
        frameToCenter.origin.y = 0;
    }
    self.tilingView.frame = frameToCenter;
}


#pragma mark - Map configuration

- (void)displayTiledMap
{
    // clear views for the previous image
    [self.tilingView removeFromSuperview];
    self.tilingView = nil;

    // reset our zoomScale to 1.0 / device scale before doing any further calculations
    self.scrollView.zoomScale = 1.0f;

    // create new tiling view
    self.tilingView = [[METilingView alloc] initWithMapBundle:self.mapBundle];
    [self.scrollView addSubview:self.tilingView];

    // configure the map
    [self configureForMap:self.mapBundle];
    [self centerZoomingView];
    self.tilingView.showsUserLocation = self.trackUserLocation;
    self.tilingView.showsBeacons = self.showBeacons;
}

- (void)configureForMap:(MEMapBundle *)mapBundle
{
    self.scrollView.contentSize = mapBundle.imageSize;
    self.scrollView.minimumZoomScale = mapBundle.minScale;
    self.scrollView.maximumZoomScale = mapBundle.maxScale;
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
}

#pragma mark - UIScrollViewDelegate (Zooming) implementation

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.tilingView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (fabs(self.tilingView.zoomScale - scrollView.zoomScale) >= 1) {
        self.tilingView.zoomScale = scrollView.zoomScale;
    }
    [self centerZoomingView];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self.tilingView cancelAnimations];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    self.tilingView.zoomScale = scale;
    [self.tilingView resumeAnimations];
}

#pragma mark - Tracking location updates

- (void)locationUpdated:(NSNotification *)notification
{
    Point3D location = self.navigationManager.currentLocation;
    self.tilingView.userLocation = CGPointMake((CGFloat) (location.x / self.mapBundle.maxScale),
            (CGFloat) (location.y / self.mapBundle.maxScale));
    self.tilingView.highlightedBeacons = [NSSet setWithArray:notification.userInfo[MENavigationNotificationUserInfoKeys.pivotBeaconsKey]];
}

@end