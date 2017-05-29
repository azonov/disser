//
// Created by Yaroslav Vorontsov on 19.03.15.
// Copyright (c) 2015 DataArt. All rights reserved.
//

@import CocoaLumberjack;
#import "WCDiscoveryManager.h"
#import "WCPeripheralConnection.h"
#import "HardwareInfo.h"


const struct WCDiscoveryManagerNotifications WCDiscoveryManagerNotifications = {
        .Keys = {
                .peripheral = @"Peripheral",
                .connection = @"Connection",
                .error = @"Error"
        },
        .bluetoothNotAuthorized = @"BluetoothNotAuthorized",
        .bluetoothNotSupported = @"BluetoothNotSupported",
        .peripheralDiscovered = @"PeripheralDiscovered",
        .peripheralConnected = @"PeripheralConnected",
        .peripheralDisconnected = @"PeripheralDisconnected",
        .peripheralConnectionFailed = @"PeripheralConnectionFailed",
};

@interface WCDiscoveryManager() <CBCentralManagerDelegate>
@property (strong, nonatomic, readonly) CBCentralManager *centralManager;
@property (strong, nonatomic, readonly) NSNotificationCenter *center;
@property (strong, nonatomic, readonly) NSMutableDictionary *peripherals;
@property (strong, nonatomic, readonly) NSMutableDictionary *hardware;
@property (strong, nonatomic, readonly) dispatch_queue_t callbackQueue;
@property (assign, nonatomic, readwrite) BOOL scanning;
@end

@implementation WCDiscoveryManager

#pragma mark - Initialization

- (instancetype)init
{
    if ((self = [super init]))
    {
        _callbackQueue = dispatch_queue_create("com.dataart.wellcore-calibrator:ble-ranging", DISPATCH_QUEUE_CONCURRENT);
        NSDictionary *options = @{ CBCentralManagerOptionShowPowerAlertKey: @(YES) };
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:self.callbackQueue
                                                             options:options];
        _peripherals = [@{} mutableCopy];
        _hardware = [@{} mutableCopy];
        _center = [NSNotificationCenter defaultCenter];
    }
    return self;
}

- (void)dealloc
{
    [self stopDiscovery];
}

#pragma mark - Discovery routines

- (void)startDiscoveryForHardware:(NSArray<id<HardwareInfo>> *)hardwareInfo
{
    // TODO: implement connecting according to the algorithm provided here:
    // https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/
    // BestPracticesForInteractingWithARemotePeripheralDevice/BestPracticesForInteractingWithARemotePeripheralDevice.html
    // #//apple_ref/doc/uid/TP40013257-CH6-SW1
    // This is needed because once device is connected and disconnected,
    // it's impossible to discover the same device once again.
    // It may also worth trying to use duplicates for the same purpose and filter the incoming connections manually
    if (!self.scanning) {
        NSDictionary *scanOptions = @{ CBCentralManagerScanOptionAllowDuplicatesKey: @(NO) };
        NSArray<CBUUID *> *services = [hardwareInfo valueForKeyPath:@"scannableServiceID"];
        [self.hardware addEntriesFromDictionary:[NSDictionary dictionaryWithObjects:hardwareInfo forKeys:services]];
        [self.centralManager scanForPeripheralsWithServices:services options:scanOptions];
        self.scanning = YES;
    }
}

- (void)stopDiscovery
{
    if (self.scanning) {
        [self.centralManager stopScan];
        [self.hardware removeAllObjects];
        self.scanning = NO;
    }
}

#pragma mark - Utility methods

- (NSArray<CBUUID *> *)discoveredServicesForDiscoveryData:(NSDictionary *)data
{
    NSArray<CBUUID *> *retrievedIdentifiers = [data[CBAdvertisementDataServiceDataKey] allKeys];
    NSArray<CBUUID *> *additionalServices = data[CBAdvertisementDataServiceUUIDsKey];
    // Check also service UUIDs discovered inside kCBAdvDataServiceUUIDs row
    if (additionalServices != nil && retrievedIdentifiers != nil) {
        return [retrievedIdentifiers arrayByAddingObjectsFromArray:additionalServices];
    }
    return retrievedIdentifiers ?: additionalServices;
}

- (id <HardwareInfo>)hardwareForIdentifiers:(NSArray<CBUUID *> *)identifiers
{
    // Find the intersection between the sets of received and available IDs
    NSSet<CBUUID *> *hardwareIDs = [NSSet setWithArray:self.hardware.allKeys];
    NSMutableSet<CBUUID *> *receivedIDs = [NSMutableSet setWithArray:identifiers];
    [receivedIDs intersectSet:hardwareIDs];
    // Enumerate hardware and select using the first match
    __block id<HardwareInfo> hardware = nil;
    [receivedIDs enumerateObjectsUsingBlock:^(CBUUID *obj, BOOL *stop) {
        *stop = (hardware = self.hardware[obj]) != nil;
    }];
    return hardware;
}

#pragma mark - CBCentralManagerDelegate implementation

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    DDLogInfo(@"Bluetooth state has changed to %zd", central.state);
    switch (central.state) {
        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateResetting:
            // Wait until state is clarified, noop
            break;
        case CBCentralManagerStatePoweredOff:
        case CBCentralManagerStatePoweredOn:
            // Power alert is shown automatically, noop. Otherwise just continue
            break;
        case CBCentralManagerStateUnauthorized:
            [self.center postNotificationName:WCDiscoveryManagerNotifications.bluetoothNotAuthorized object:self];
            // Bluetooth is not allowed for this app
            break;
        case CBCentralManagerStateUnsupported:
            [self.center postNotificationName:WCDiscoveryManagerNotifications.bluetoothNotSupported object:self];
            // Bluetooth is unsupported on this device - fatal error!
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    // DO NOT BELIEVE to this flag! Try connecting without additional checks
    // BOOL connectable = [advertisementData[CBAdvertisementDataIsConnectable] boolValue];
    // Skip all peripherals which doesn't have any kind of advertisement data OR can't be connected at all
    DDLogVerbose(@"Discovered a peripheral %@ with data %@ and RSSI %@", peripheral, advertisementData, RSSI);
    NSArray<CBUUID *> *retrievedIdentifiers = [self discoveredServicesForDiscoveryData:advertisementData];
    if (retrievedIdentifiers.count > 0 && peripheral.state == CBPeripheralStateDisconnected) {
        // For disconnected peripherals which ARE connectable: save connection info
        id<HardwareInfo> hardware = [self hardwareForIdentifiers:retrievedIdentifiers];
        if (hardware != nil) {
            WCPeripheralConnection *connection = [[WCPeripheralConnection alloc] initWithPeripheral:peripheral
                                                                                           hardware:hardware
                                                                                               rssi:RSSI];
            self.peripherals[peripheral] = connection;
            // Send a discovery notification
            [self.center postNotificationName:WCDiscoveryManagerNotifications.peripheralDiscovered
                                       object:self
                                     userInfo:@{ WCDiscoveryManagerNotifications.Keys.peripheral: peripheral}];
            // Try connecting the peripheral
            [central connectPeripheral:peripheral options:@{}];
        } else {
            DDLogInfo(@"Unknown hardware detected");
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    WCPeripheralConnection *connection = self.peripherals[peripheral];
    [self.center postNotificationName:WCDiscoveryManagerNotifications.peripheralConnected
                               object:self
                             userInfo:@{ WCDiscoveryManagerNotifications.Keys.connection: connection }];
    DDLogVerbose(@"Peripheral %@ was connected", peripheral);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    WCPeripheralConnection *connection = self.peripherals[peripheral];
    [self.center postNotificationName:WCDiscoveryManagerNotifications.peripheralDisconnected
                               object:self
                             userInfo:@{ WCDiscoveryManagerNotifications.Keys.connection: connection}];
    [self.peripherals removeObjectForKey:peripheral];
    DDLogVerbose(@"Peripheral %@ has been disconnected", peripheral.identifier);
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self.center postNotificationName:WCDiscoveryManagerNotifications.peripheralConnectionFailed
                               object:self
                             userInfo:@{
                                     WCDiscoveryManagerNotifications.Keys.peripheral: peripheral,
                                     WCDiscoveryManagerNotifications.Keys.error: error
                             }];
    [self.peripherals removeObjectForKey:peripheral];
    DDLogWarn(@"Failed to connect peripheral due to the following error: %@ (%@)", error.localizedDescription, error);
}

@end