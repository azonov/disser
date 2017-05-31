//
// Created by Yaroslav Vorontsov on 31.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@protocol ConnectionDataSerializer <NSObject>
- (id)valueForData:(NSData *)data characteristic:(CBUUID *)characteristic;
- (NSData *)dataForValue:(id)value characteristic:(CBUUID *)characteristic;
- (NSData *)dataForAuthenticationWithPassword:(NSString *)password;
- (NSData *)dataForAlteringPassword:(NSString *)password;
@end