//
// Created by Yaroslav Vorontsov on 23.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

extern const struct CharacteristicType {
    __unsafe_unretained NSString *const constant;
    __unsafe_unretained NSString *const text;
    __unsafe_unretained NSString *const action;
    __unsafe_unretained NSString *const number;
    __unsafe_unretained NSString *const range;
} CharacteristicType;

@protocol HardwareInfo <NSObject>
@property (strong, nonatomic, readonly) NSDictionary *characteristics;
@property (strong, nonatomic, readonly) CBUUID *scannableServiceID;
@property (strong, nonatomic, readonly) CBUUID *primaryServiceID;
@property (strong, nonatomic, readonly) CBUUID *batteryServiceID;
@property (strong, nonatomic, readonly) CBUUID *passwordServiceID;
@property (copy, nonatomic, readonly) NSString *name;
@property (assign, nonatomic, readonly) BOOL requiresPassword;
@end

@protocol CharacteristicInfo <NSObject>
@property (strong, nonatomic, readonly) CBUUID *identifier;
@property (copy, nonatomic, readonly) NSString *name;
@property (copy, nonatomic, readonly) NSString *type;
@property (assign, nonatomic, readonly) NSRange limits;
@end