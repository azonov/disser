//
// Created by Yaroslav Vorontsov on 24.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <objc/runtime.h>
#import <XLForm/XLForm.h>
#import "WCMulticastDelegate.h"

#pragma mark - NSObject+ProtocolType implementation

@implementation NSObject(WCProtocolType)

+ (NSString *)keyPathForPropertyImplementingProtocol:(Protocol *)aProtocol
{
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    NSString *protocolName = NSStringFromProtocol(aProtocol);
    NSString *keyPath = nil;
    BOOL found = NO;
    for (unsigned int i = 0; i < count && !found; ++i) {
        objc_property_t p = properties[i];
        // Get attributes
        const char *attrs = property_getAttributes(p);
        // Get type info
        size_t length = strchr( attrs, ',' ) - attrs;
        // Allocate a buffer for type info
        char *type_enc = malloc(length + 1);
        type_enc[length] = 0;
        memcpy(type_enc, attrs, length);
        NSString *typeInfo = [NSString stringWithCString:type_enc encoding:NSUTF8StringEncoding];
        free(type_enc);
        if ((found = [typeInfo containsString:protocolName])) {
            keyPath = [NSString stringWithCString:property_getName(p) encoding:NSUTF8StringEncoding];
        }
    }
    free(properties);
    return keyPath;
}

- (NSString *)keyPathForPropertyImplementingProtocol:(Protocol *)aProtocol
{
    return [self.class keyPathForPropertyImplementingProtocol:aProtocol];
}

@end

#pragma mark - WCMulticastDelegate implementation

@interface WCMulticastDelegate()
@property (strong, nonatomic, readonly) NSHashTable *innerDelegates;
@property (strong, nonatomic, readonly) Protocol *protocol;
@property (copy, nonatomic, readonly) NSString *delegateKeyPath;
@property (weak, nonatomic, readonly) id observable;
@end

@implementation WCMulticastDelegate

#pragma mark - Initialization

- (instancetype)initWithProtocol:(Protocol *)aProtocol observable:(id)observable
{
    _protocol = aProtocol;
    _observable = observable;
    _delegateKeyPath = [[observable keyPathForPropertyImplementingProtocol:aProtocol] copy];
    _innerDelegates = [NSHashTable weakObjectsHashTable];
    return self;
}

#pragma mark - Subscription management

- (void)addDelegate:(id)listener
{
    // A listener should implement the required protocol
    NSAssert([listener conformsToProtocol:self.protocol], @"Listener doesn't conform to %@", self.protocol);
    [self.innerDelegates addObject:listener];
    // Once delegate is added, it's required to rebind the "delegate" property of actual object because some
    // objects may implement only a part of methods declared in delegate protocol
    [self performBinding];
}

- (void)removeDelegate:(id)listener
{
    [self.innerDelegates removeObject:listener];
    [self performBinding];
}

// This function's purpose is to update _delegateFlags structures, where it's necessary
- (void)performBinding
{
    if (self.delegateKeyPath != nil) {
        // Trigger the update of _delegateFlags
        [self.observable setValue:nil forKey:self.delegateKeyPath];
        [self.observable setValue:self forKey:self.delegateKeyPath];
    }
}

#pragma mark - Method dispatching

// Essential for protocol handling
- (BOOL)respondsToSelector:(SEL)aSelector
{
    for (id delegate in self.innerDelegates) {
        // At least one instance should respond to the selector
        if ([delegate respondsToSelector:aSelector]) {
            return YES;
        }
    }
    // To prevent crashes, return NO. Otherwise the selector won't be found
    return NO;
}

// If we need to check that the method is mandatory, we should use the technique described here:
// http://stackoverflow.com/questions/21767576/how-can-i-check-if-a-class-implements-all-methods-in-a-protocol-in-obj-c
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    for (id delegate in self.innerDelegates) {
        if ([delegate respondsToSelector:selector]) {
            return [delegate methodSignatureForSelector:selector];
        }
    }
    // If not found, call the default implementation
    return [super methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    for (id delegate in self.innerDelegates) {
        if ([delegate respondsToSelector:invocation.selector]) {
            // Invoke methods only for those instances who implement them
            [invocation invokeWithTarget:delegate];
        }
    }
}

@end