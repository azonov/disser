//
// Created by Yaroslav Vorontsov on 29.07.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

@import CocoaLumberjack;
#import "WCBeaconDetailsViewController.h"
#import "HardwareDescription.h"
#import "WCPeripheralConnection.h"
#import "WCPeripheralConfigurationInteractor.h"
#import "UIViewController+Additions.h"
#import "Main.storyboard.h"
#import "CollectionUtils.h"

@interface WCBeaconDetailsViewController() <WCConfigurationInteractorDelegate>
@property (strong, nonatomic, readonly) WCPeripheralConfigurationInteractor *interactor;
@property (strong, nonatomic, readonly) NSMutableSet<NSString *> *dirtyRowTags;
@end

@implementation WCBeaconDetailsViewController
{
    WCPeripheralConfigurationInteractor *_interactor;
    NSMutableSet *_dirtyRowTags;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.form = [self makeForm];
    self.navigationItem.rightBarButtonItem = [self commitItem];
    if (self.connection.requiresPassword) {
        [self presentViewController:[self passwordPromptController] animated:YES completion:nil];
    } else {
        [self.interactor readAllCharacteristics];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // Dismiss SVProgressHUD and cancel all I/O operations
    [SVProgressHUD dismiss];
    [self.interactor cancelAllPendingTransactions];
}

#pragma mark - Overridden getters/setters

- (WCPeripheralConfigurationInteractor *)interactor
{
    if (!_interactor) {
        _interactor = [[WCPeripheralConfigurationInteractor alloc] initWithConnection:self.connection];
        _interactor.delegate = self;
    }
    return _interactor;
}

- (NSMutableSet<NSString *> *)dirtyRowTags
{
    if (!_dirtyRowTags) {
        _dirtyRowTags = [NSMutableSet set];
    }
    return _dirtyRowTags;
}

#pragma mark - Factory methods

- (UIBarButtonItem *)commitItem
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                          target:self
                                                                          action:@selector(saveTapped:)];
    return item;
}

- (UIAlertController *)passwordPromptController
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Password required"
                                                                        message:@"Enter the password to proceed"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    __weak __block UITextField *passwordTextField = nil;
    // Add password text field
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        passwordTextField = textField;
        textField.secureTextEntry = YES;
    }];
    // Default actions are Cancel and OK
    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self.interactor authenticateWithPassword:passwordTextField.text];
                                                         }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [self performSegueWithIdentifier:BeaconDetailsSegues.unwindToBeaconList];
                                                         }];
    [controller addAction:cancelAction];
    [controller addAction:submitAction];
    return controller;
}

- (UIAlertController *)errorAlertControllerForErrors:(NSDictionary<CBUUID *, NSError *> *)errors
{
    NSArray *propertyNames = [errors.allKeys map:^id(CBUUID *identifier) { return identifier.UUIDString; }];
    NSString *message = [NSString stringWithFormat:@"Failed to complete transaction for the following properties: %@",
                                                   [propertyNames componentsJoinedByString:@","]];
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Bluetooth Error"
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [controller addAction:defaultAction];
    return controller;
}

#pragma mark - Interaction delegate

- (void)interactorDidStartTransaction:(WCPeripheralConfigurationInteractor *)interactor
{
    [SVProgressHUD showProgress:-1.0f status:interactor.connectionStatus];
}

- (void)interactorDidFinishTransaction:(WCPeripheralConfigurationInteractor *)interactor
                            withValues:(NSDictionary<CBUUID *, id> *)values
                                errors:(NSDictionary<CBUUID *, NSError *> *)errors
{
    [SVProgressHUD popActivity];
    // Present errors if there are any
    if (errors.count > 0) {
        [self presentViewController:[self errorAlertControllerForErrors:errors] animated:YES completion:nil];
    }
    // Configure cells with values which were read
    if (values.count > 0) {
        for (CBUUID *key in values) {
            XLFormRowDescriptor *row = [self.form formRowWithTag:key.UUIDString];
            row.value = values[key];
        }
        [self.tableView reloadData];
    }
}

#pragma mark - Actions

- (void)saveTapped:(UIBarButtonItem *)sender
{
    if (self.dirtyRowTags.count > 0) {
        NSMutableDictionary<CBUUID *, id> *values = [NSMutableDictionary dictionaryWithCapacity:self.dirtyRowTags.count];
        for (NSString *tag in self.dirtyRowTags) {
            values[[CBUUID UUIDWithString:tag]] = [self.form formRowWithTag:tag].value;
        }
        [self.interactor writeCharacteristics:values];
    }
}

#pragma mark - Form declarations

- (XLFormDescriptor *)makeForm
{
    id<HardwareInfo> hardware = self.connection.hardware;
    XLFormDescriptor *form = [XLFormDescriptor formDescriptorWithTitle:@"Beacon properties"];
    // Use alphabetic ordering inside form
    NSArray *sortedSections = [hardware.characteristics.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in sortedSections) {
        [form addFormSection:[self sectionWithTitle:key forCharacteristics:hardware.characteristics[key]]];
    }
    return form;
}

- (XLFormSectionDescriptor *)sectionWithTitle:(NSString *)title forCharacteristics:(NSArray *)characteristics
{
    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSectionWithTitle:title];
    for (id<CharacteristicInfo> characteristic in characteristics) {
        // Use characteristic's UUID as tag. This will help to identify which value should be where
        NSString *formType = [self.interactor formTypeForCharacteristic:characteristic];
        XLFormRowDescriptor *row = [XLFormRowDescriptor formRowDescriptorWithTag:characteristic.identifier.UUIDString
                                                                         rowType:formType
                                                                           title:characteristic.name];
        [self configureRow:row forCharacteristic:characteristic];
        [section addFormRow:row];
    }
    return section;
}

// Look here for typical configurations:
// https://github.com/xmartlabs/XLForm/blob/master/Examples/Objective-C/Examples/Others/OthersFormViewController.m
- (void)configureRow:(XLFormRowDescriptor *)row forCharacteristic:(id<CharacteristicInfo>)info
{
    [row.cellConfigAtConfigure addEntriesFromDictionary:[self cellConfigForCharacteristic:info]];
    row.onChangeBlock = ^(id oldValue, id newValue, XLFormRowDescriptor *rowDescriptor) {
        DDLogVerbose(@"Cell %@: changed value from %@ to %@", rowDescriptor.tag, oldValue, newValue);
        [self.dirtyRowTags addObject:rowDescriptor.tag];
    };
}

- (NSDictionary *)cellConfigForCharacteristic:(id<CharacteristicInfo>)info
{
    // Caching is not needed due to unique info names/placeholders
    NSString *key = [self.interactor formTypeForCharacteristic:info];
    // Text fields
    if ([key isEqualToString:XLFormRowDescriptorTypeText]) {
        return @{
                @"textField.placeholder": info.name,
                @"textField.textAlignment": @(NSTextAlignmentRight)
        };
    }
    // Integer values
    if ([key isEqualToString:XLFormRowDescriptorTypeInteger]) {
        return @{
                @"textField.placeholder": info.name,
                @"textField.textAlignment": @(NSTextAlignmentRight)
        };
    }
    // Sliders
    if ([key isEqualToString:XLFormRowDescriptorTypeSlider]) {
        return @{
                @"slider.minimumValue": @(info.limits.location),
                @"slider.maximumValue": @(NSMaxRange(info.limits)),
                @"slider.continuous": @(NO),
                @"steps": @(NSMaxRange(info.limits) - info.limits.location)
        };
    }
    // All the others
    return @{};
}

@end