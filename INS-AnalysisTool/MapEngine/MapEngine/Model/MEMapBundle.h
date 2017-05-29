//
// Created by Yaroslav Vorontsov on 13.04.15.
// Copyright (c) 2015 Yaroslav Vorontsov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern const struct MapBundleItems {
    __unsafe_unretained NSString *const tilesDirectory;
    __unsafe_unretained NSString *const metadataFile;
    __unsafe_unretained NSString *const previewFile;
    __unsafe_unretained NSString *const beaconsFile;
} MapBundleItems;

extern const struct MapBundleMetadataKeys {
    __unsafe_unretained NSString *const name;
    __unsafe_unretained NSString *const width;
    __unsafe_unretained NSString *const height;
    __unsafe_unretained NSString *const tileSetCount;
    __unsafe_unretained NSString *const maxScale;
    __unsafe_unretained NSString *const tileSize;
    __unsafe_unretained NSString *const buildingUUID;
    __unsafe_unretained NSString *const major;
    __unsafe_unretained NSString *const mapDPI;
    __unsafe_unretained NSString *const mapScale;
} MapBundleMetadataKeys;

extern const struct BeaconMetadataKeys {
    __unsafe_unretained NSString *const minor;
    __unsafe_unretained NSString *const x;
    __unsafe_unretained NSString *const y;
    __unsafe_unretained NSString *const h;
} BeaconMetadataKeys;

/**
* This class is a logical representation of a real bundle with the map.
* Bundle's structure is:
* - preview.png image
* - metadata.plist file
* - beacons.plist file with the beacon pixel coordinates (on a hi-res map)
* - Tiles directory with the following structure:
*   - 1st level is a set of directories containing tiles for different scales
*   - 2nd level is a set of directories containing rows
*   - 3rd level is a set of tiles for the specified row
*   I.e., relative path is ./Tiles/2/0/2.png
*
*   Some words on tile preparation
*   Tiles can be prepared using the following tools:
*   - Adobe Photoshop - Slice tool
*   - SliceTool
*   - Tile Cutter
*/
@interface MEMapBundle : NSBundle
// Map metadata loaded from plist
@property (strong, nonatomic, readonly) NSDictionary *metadata;
// Building UUID used as an area identifier
@property (strong, nonatomic, readonly) NSUUID *buildingUUID;
// Beacon location information from plist
@property (strong, nonatomic, readonly) NSArray *beacons;
// Preview image included into bundle
@property (strong, nonatomic, readonly) UIImage *previewImage;
// Map name from metadata
@property (copy, nonatomic, readonly) NSString *name;
// Major number is an identifier of a floor. Map is flat ATM - this id will be removed in future when map becomes multilayer
@property (assign, nonatomic, readonly) uint16_t major;
// Tile set count
@property (assign, nonatomic, readonly) NSUInteger tileSetCount;
// Tile DPI
@property (assign, nonatomic, readonly) NSUInteger mapDPI;
// Levels of details available. If we have N different tile sets, the count of levels of details is N-1. Used by layer
@property (assign, nonatomic, readonly) NSUInteger levelsOfDetails;
// Image size at @1x resolution
@property (assign, nonatomic, readonly) CGSize imageSize;
// Image bounds for hit test
@property (assign, nonatomic, readonly) CGRect imageBounds;
// Maximal tile size in PIXELS. Default is 256*256
@property (assign, nonatomic, readonly) CGSize tileSize;
// Actual map scale - centimeters per meter
@property (assign, nonatomic, readonly) CGFloat mapScale;
// Minimal scale for a scroll view. Default is 1
@property (assign, nonatomic, readonly) CGFloat minScale;
// Maximal scale for a scroll view calculated based on available levels of details. Used by UIScrollView
@property (assign, nonatomic, readonly) CGFloat maxScale;
// Returns an image for the specified scale (which is a power of 2), row and column
- (UIImage *)tileForScale:(CGFloat)scale row:(int)row col:(int)col;
// Returns tile size in POINTS based on the scale provided
- (CGSize)tileSizeForScale:(CGFloat)scale;
// Converts meters to pixels based on the maximal map scale and DPI value
- (double)pixelsFromCentimeters:(double)centimeters;
// Converts pixels to meters based on the maximal map scale and DPI value;
- (double)centimetersFromPixels:(double)pixels;
@end