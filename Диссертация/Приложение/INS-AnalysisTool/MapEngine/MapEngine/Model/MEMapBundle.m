//
// Created by Yaroslav Vorontsov on 13.04.15.
// Copyright (c) 2015 Yaroslav Vorontsov. All rights reserved.
//

@import CocoaLumberjack;
#import "MEMapBundle.h"
#import "MEMapBeacon.h"
#import "MEConstants.h"

const struct MapBundleItems MapBundleItems = {
        .tilesDirectory = @"Tiles",
        .previewFile = @"preview.png",
        .metadataFile = @"metadata.plist",
        .beaconsFile = @"beacons.plist",
};

const struct MapBundleMetadataKeys MapBundleMetadataKeys = {
        .name = @"name",
        .width = @"width",
        .height = @"height",
        .tileSetCount = @"tileSetCount",
        .maxScale = @"maxScale",
        .tileSize = @"tileSize",
        .buildingUUID = @"buildingUUID",
        .major = @"major",
        .mapDPI = @"mapDPI",
        .mapScale = @"mapScale",
};

const struct BeaconMetadataKeys BeaconMetadataKeys = {
        .minor = @"minor",
        .x = @"x",
        .y = @"y",
        .h = @"h",
};

@implementation MEMapBundle
{
    UIImage *_previewImage;
    NSMutableDictionary *_metadata;
    NSArray *_beacons;
    NSUUID *_buildingUUID;
}

#pragma mark - Getters and setters

- (NSDictionary *)metadata
{
    if (!_metadata) {
        NSString *path = [self.bundlePath stringByAppendingPathComponent:MapBundleItems.metadataFile];
        _metadata = [[NSDictionary dictionaryWithContentsOfFile:path] mutableCopy];
    }
    return _metadata;
}

- (NSArray *)beacons
{
    if (!_beacons) {
        NSString *path = [self.bundlePath stringByAppendingPathComponent:MapBundleItems.beaconsFile];
        NSArray *dictBeacons = [NSArray arrayWithContentsOfFile:path];
        NSMutableArray *beacons = [NSMutableArray arrayWithCapacity:dictBeacons.count];
        [dictBeacons enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            MEMapBeacon *beacon = [[MEMapBeacon alloc] initWithDictionary:obj mapBundle:self];
            [beacons addObject:beacon];
        }];
        _beacons = [beacons sortedArrayUsingComparator:^NSComparisonResult(MEMapBeacon *obj1, MEMapBeacon *obj2) {
            if (obj1.minor == obj2.minor)
                return NSOrderedSame;
            return obj1.minor < obj2.minor ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
    return _beacons;
}

- (NSUUID *)buildingUUID
{
    if (!_buildingUUID) {
        _buildingUUID = [[NSUUID alloc] initWithUUIDString:self.metadata[MapBundleMetadataKeys.buildingUUID]];
    }
    return _buildingUUID;
}

- (UIImage *)previewImage
{
    if (!_previewImage) {
        NSString *path = [self.bundlePath stringByAppendingPathComponent:MapBundleItems.previewFile];
        _previewImage = [UIImage imageWithContentsOfFile:path];
    }
    return _previewImage;
}

- (NSString *)name
{
    return self.metadata[MapBundleMetadataKeys.name];
}

- (uint16_t)major
{
    return [self.metadata[MapBundleMetadataKeys.major] unsignedShortValue];
}

- (CGSize)imageSize
{
    // This size should be image's size at @1x resolution
    // Since map bundle includes the largest image size, we're shrinking it by the maximal scale
    CGFloat width = [self.metadata[MapBundleMetadataKeys.width] floatValue] / self.maxScale;
    CGFloat height = [self.metadata[MapBundleMetadataKeys.height] floatValue] / self.maxScale;
    return CGSizeMake(width, height);
}

- (CGRect)imageBounds
{
    return (CGRect){CGPointZero, self.imageSize};
}

- (CGSize)tileSize
{
    NSInteger tileSize = [self.metadata[MapBundleMetadataKeys.tileSize] integerValue];
    return CGSizeMake(tileSize, tileSize);
}

- (NSUInteger)tileSetCount
{
    return [self.metadata[MapBundleMetadataKeys.tileSetCount] unsignedIntegerValue];
}

- (NSUInteger)mapDPI
{
    return [self.metadata[MapBundleMetadataKeys.mapDPI] unsignedIntegerValue];
}

- (NSUInteger)levelsOfDetails
{
    return self.tileSetCount - 1;
}

- (CGFloat)mapScale
{
    return [self.metadata[MapBundleMetadataKeys.mapScale] floatValue];
}

- (CGFloat)minScale
{
    return 1.0f;
}

- (CGFloat)maxScale
{
    NSNumber *maxScale = self.metadata[MapBundleMetadataKeys.maxScale];
    if (!maxScale) {
        maxScale = @(powf(2.0f, self.levelsOfDetails));
        _metadata[MapBundleMetadataKeys.maxScale] = maxScale;
    }
    return maxScale.floatValue;
}

- (UIImage *)tileForScale:(CGFloat)scale row:(int)row col:(int)col
{
    DDLogDebug(@"Requested an image (%d, %d) for scale %f", row, col, scale);
    // we use "imageWithContentsOfFile:" instead of "imageNamed:" here because we don't want UIImage to cache our tiles
    NSString *path = [NSString stringWithFormat:@"%@/%@/%d/%d/%d.png",
                                                self.bundlePath, MapBundleItems.tilesDirectory,
                                                (int) ceil(scale), row, col];
    return [UIImage imageWithContentsOfFile:path];
}

- (CGSize)tileSizeForScale:(CGFloat)scale
{
    /**
    * From Nick Lockwood's book (iOS Core Animation: Advanced Techniques)
    *
    * Interestingly, the tileSize property of a CATiledLayer instance is measured in PIXELS, not POINTS.
    * So by increasing contentsScale property of a view/layer for Retina displays (2x/3x), we automatically
    * at least halve the default tile size (i.e., for 256x256 and @2x display it scales to 128x128)
    * The same thing is confirmed by the comments in CATiledLayer.h header and Apple's PhotoScroller app sample code
    *
    * To avoid providing THREE different tile sets for each ppi resolution, we need to modify the rendering code and
    * adjust the tile size to be N times greater
    */
    return CGSizeApplyAffineTransform(self.tileSize, CGAffineTransformMakeScale(scale, scale));
}

- (double)pixelsFromCentimeters:(double)centimeters
{
    /**
    * Conversion formula inches->dpi:
    *   d_pix = d_inches * dpi = (d_cm / 2.54) * dpi
    * Unit check:
    *  [pix] = [inch] * [pix/inch] = [cm] * [inch/cm] * [pix/inch]
    *
    *  d_cm is cm / mapScale
    *
    *  So final formula is
    *  d_pix = (centimeters / mapScale) / 2.54 * dpi
    */
    return (centimeters * self.mapDPI) / (2.54f * self.mapScale);
}

- (double)centimetersFromPixels:(double)pixels
{
    return (2.54f * self.mapScale * pixels) / self.mapDPI;
}


@end