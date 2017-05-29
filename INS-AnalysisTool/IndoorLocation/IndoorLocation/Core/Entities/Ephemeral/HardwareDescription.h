//
// Created by Yaroslav Vorontsov on 01.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;
#import "HardwareInfo.h"

@class CharacteristicDescription;

// Provides a description for a whole class of devices
@interface HardwareDescription : NSObject <HardwareInfo>
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end


// Provides a description for a characteristic of a device
@interface CharacteristicDescription: NSObject <CharacteristicInfo>
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end