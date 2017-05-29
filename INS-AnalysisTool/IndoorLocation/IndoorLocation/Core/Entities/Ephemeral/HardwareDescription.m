//
// Created by Yaroslav Vorontsov on 01.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "HardwareDescription.h"
#import "CollectionUtils.h"


@implementation HardwareDescription
@synthesize scannableServiceID = _scannableServiceID;
@synthesize primaryServiceID = _primaryServiceID;
@synthesize batteryServiceID = _batteryServiceID;
@synthesize passwordServiceID = _passwordCharacteristicID;
@synthesize characteristics = _characteristics;
@synthesize name = _name;
@synthesize requiresPassword = _requiresPassword;

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    if ((self = [super init])) {
        _name = [dict[@"name"] copy];
        _requiresPassword = [dict[@"requiresPassword"] boolValue];
        _scannableServiceID = [CBUUID UUIDWithString:[dict valueForKeyPath:@"services.central"]];
        _primaryServiceID = [CBUUID UUIDWithString:[dict valueForKeyPath:@"services.primary"]];
        _batteryServiceID = [CBUUID UUIDWithString:[dict valueForKeyPath:@"services.battery"]];
        _passwordCharacteristicID = [CBUUID UUIDWithString:[dict valueForKeyPath:@"services.password"]];
        _characteristics = [dict[@"characteristics"] map:^id(NSArray *chs) {
            return [chs map:^id(NSDictionary *d) { return [[CharacteristicDescription alloc] initWithDictionary:d]; }];
        }];
    }
    return self;
}

@end


@implementation CharacteristicDescription
@synthesize identifier = _identifier;
@synthesize name = _name;
@synthesize type = _type;
@synthesize limits = _limits;

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    if ((self = [super init])) {
        _name = [dict[@"name"] copy];
        _type = [dict[@"type"] copy];
        _identifier = [CBUUID UUIDWithString:dict[@"uuid"]];
        _limits = NSRangeFromString(dict[@"limits"]);
    }
    return self;
}

@end