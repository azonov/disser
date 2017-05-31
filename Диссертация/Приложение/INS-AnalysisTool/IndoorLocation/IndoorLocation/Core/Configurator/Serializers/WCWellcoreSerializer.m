//
// Created by Yaroslav Vorontsov on 25.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCWellcoreSerializer.h"

@implementation WCWellcoreSerializer

#pragma mark - Protocol methods

- (id)valueForData:(NSData *)data characteristic:(CBUUID *)characteristic
{
    NSString *characteristicID = characteristic.UUIDString;
    // UUID
    if ([characteristicID isEqualToString:@"FFF1"]) {
        return [self uuidForData:data].UUIDString;
    }
    // Major/Minor
    if ([[NSSet setWithArray:@[@"FFF2", @"FFF3"]] containsObject:characteristicID]) {
        return @([self shortForData:data]);
    }
    // Name
    if ([characteristicID isEqualToString:@"FFF5"]) {
        return [self stringForData:data];
    }
    // TX Power/Broadcast frequency
    if ([[NSSet setWithArray:@[@"FFF4", @"FFF6", @"FFF8"]] containsObject:characteristicID]) {
        return @([self byteForData:data]);
    }
    // All the others should be transferred as raw data
    return data;
}

- (NSData *)dataForValue:(id)value characteristic:(CBUUID *)characteristic
{
    NSString *characteristicID = characteristic.UUIDString;
    // UUID
    if ([characteristicID isEqualToString:@"FFF1"]) {
        NSUUID *uuid = [value isKindOfClass:[NSUUID class]] ? value : [[NSUUID alloc] initWithUUIDString:value];
        return [self dataForUUID:uuid];
    }
    // Major/Minor
    if ([[NSSet setWithArray:@[@"FFF2", @"FFF3"]] containsObject:characteristicID]) {
        NSNumber *number = value;
        return [self dataForShort:number.shortValue];
    }
    // Name
    if ([characteristicID isEqualToString:@"FFF5"]) {
        return [self dataForString:value];
    }
    // TX Power/Broadcast frequency
    if ([[NSSet setWithArray:@[@"FFF4", @"FFF6", @"FFF8"]] containsObject:characteristicID]) {
        NSNumber *number = value;
        return [self dataForByte:number.charValue];
    }
    return value;
}

- (NSData *)dataForAuthenticationWithPassword:(NSString *)password
{
    // Passcode (0xAA + ASCII-encoded string)
    return [self dataWithPrefix:(char) 0xAA string:password];
}

- (NSData *)dataForAlteringPassword:(NSString *)password
{
    // Passcode (0xAC + ASCII-encoded string)
    return [self dataWithPrefix:(char) 0xAC string:password];
}

#pragma mark - Helper methods

- (NSData *)dataWithPrefix:(char)prefix string:(NSString *)string
{
    char bytes[] = {prefix};
    NSMutableData *data = [NSMutableData dataWithBytes:bytes length:sizeof(bytes)];
    [data appendData:[string dataUsingEncoding:NSASCIIStringEncoding]];
    return [data copy];
}

#pragma mark - Serialization/Deserialization methods for particular data types

- (char)byteForData:(NSData *)data
{
    NSParameterAssert(data.length == sizeof(char));
    char byte;
    [data getBytes:&byte length:sizeof(char)];
    return byte;
}

- (NSData *)dataForByte:(char)byte
{
    return [NSData dataWithBytes:&byte length:sizeof(char)];
}

- (short)shortForData:(NSData *)data
{
    NSParameterAssert(data.length == sizeof(short));
    char bytes[sizeof(short)];
    [data getBytes:bytes length:sizeof(short)];
    short value = (bytes[0] << 8) + bytes[1];
    return value;
}

- (NSData *)dataForShort:(short)value
{
    char bytes[] = {(char) ((value & 0xFF00) >> 8), (char) (value & 0x00FF)};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

- (NSString *)stringForData:(NSData *)data
{
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

- (NSData *)dataForString:(NSString *)string
{
    return [string dataUsingEncoding:NSASCIIStringEncoding];
}

- (NSUUID *)uuidForData:(NSData *)data
{
    NSParameterAssert(data.length == sizeof(uuid_t));
    uuid_t uuid_val;
    [data getBytes:&uuid_val length:sizeof(uuid_val)];
    return [[NSUUID alloc] initWithUUIDBytes:uuid_val];
}

- (NSData *)dataForUUID:(NSUUID *)uuid
{
    uuid_t uuid_val;
    memset(&uuid_val, 0, sizeof(uuid_val));
    [uuid getUUIDBytes:uuid_val];
    return [NSData dataWithBytes:uuid_val length:sizeof(uuid_val)];
}

@end