//
// Created by Yaroslav Vorontsov on 24.04.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

#import "CLBeacon+Additions.h"

@implementation CLBeacon (Additions)

// According to data sheet, TX power is C5 -> -59 dB
- (CLLocationDistance)distance
{
    if (self.rssi != 0) {
        double ratio = self.rssi / -59.0;
        if (ratio < 1) {
            return pow(ratio, 10) * 100;
        }
        return (0.89976 * pow(ratio, 7.7095) + 0.111) * 100;
    }
    return -1;
}

// No correction applied to beacons by default
- (double)affectionCorrection
{
    return 1;
}

@end