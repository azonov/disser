//
// Created by Yaroslav Vorontsov on 03.08.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import <objc/runtime.h>
#import "UIViewController+Additions.h"

#pragma mark - Implementation of a proxy segue

@interface UISegueProxy: NSProxy
- (instancetype)initWithSegue:(UIStoryboardSegue *)segue;
@end


@implementation UISegueProxy
{
    UIStoryboardSegue *_innerSegue;
}

#pragma mark - Initializers

- (instancetype)initWithSegue:(UIStoryboardSegue *)segue
{
    _innerSegue = segue;
    return self;
}

#pragma mark - NSProxy methods

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [_innerSegue methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:_innerSegue];
}

#pragma mark - Method implementation

- (__kindof UIViewController *)destinationViewController
{
    if ([_innerSegue.destinationViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = _innerSegue.destinationViewController;
        return navigationController.topViewController;
    }
    return _innerSegue.destinationViewController;
}

@end

#pragma mark - Implementation of the category

@implementation UIViewController (Additions)

static NSString *const blocksKey = @"BlocksKey";

#pragma mark - Swizzling stuff

+ (void)initialize
{
    [self swizzlePrepareForSegue];
}

+ (void)swizzlePrepareForSegue
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL original = @selector(prepareForSegue:sender:);
        SEL swizzled = @selector(prepareForNewSegue:sender:);
        Method origImpl = class_getInstanceMethod(class, original);
        Method swizzledImpl = class_getInstanceMethod(class, swizzled);
        if (class_addMethod(class, original, method_getImplementation(swizzledImpl), method_getTypeEncoding(swizzledImpl))) {
            class_replaceMethod(class, swizzled, method_getImplementation(origImpl), method_getTypeEncoding(origImpl));
        } else {
            method_exchangeImplementations(origImpl, swizzledImpl);
        }
    });
}

#pragma mark - Getters and setters

- (NSMutableDictionary *)segueConfigurationBlocks
{
    NSMutableDictionary *blocks = objc_getAssociatedObject(self, &blocksKey);
    if (blocks == nil) {
        blocks = [@{} mutableCopy];
        objc_setAssociatedObject(self, &blocksKey, blocks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return blocks;
}

#pragma mark - Segue execution methods

- (void)performSegueWithIdentifier:(NSString *)identifier
{
    [self performSegueWithIdentifier:identifier sender:self];
}

- (void)performSegueWithIdentifier:(NSString *)identifier configurationBlock:(SegueConfigurationBlock)block
{
    [self performSegueWithIdentifier:identifier sender:self configurationBlock:block];
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender configurationBlock:(SegueConfigurationBlock)block
{
    NSParameterAssert(identifier != nil);
    NSParameterAssert(block != nil);
    self.segueConfigurationBlocks[identifier] = block;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:identifier sender:sender];
    });
}

#pragma mark - Swizzled implementation

- (void)prepareForNewSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Call original implementation
    [self performSelector:@selector(prepareForNewSegue:sender:) withObject:self withObject:sender];
    SegueConfigurationBlock block = self.segueConfigurationBlocks[segue.identifier];
    if (block != nil) {
        // Check that block exists, call it and remove it from the cache
        block((id) [[UISegueProxy alloc] initWithSegue:segue]);
        [self.segueConfigurationBlocks removeObjectForKey:segue.identifier];
    }
}

@end