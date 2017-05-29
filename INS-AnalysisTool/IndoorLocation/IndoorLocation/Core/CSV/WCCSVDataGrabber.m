//
// Created by Yaroslav Vorontsov on 01.06.16.
// Copyright (c) 2016 DataArt. All rights reserved.
//

#import "WCCSVDataGrabber.h"

@interface WCCSVDataGrabber()
@property (strong, nonatomic, readonly) NSString *filePath;
@property (strong, nonatomic, readonly) NSFileHandle *fileHandle;
@property (strong, nonatomic, readonly) dispatch_queue_t ioQueue;
@end

@implementation WCCSVDataGrabber
{
    NSString *_fileName;
    NSString *_filePath;
    NSFileHandle *_fileHandle;
}

#pragma mark - Initialization and deallocation

- (instancetype)init
{
    if ((self = [super init])) {
        _ioQueue = dispatch_queue_create("com.dataart.wellcore-calibrator:csv-io", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc
{
    if (_fileHandle) {
        [_fileHandle closeFile];
    }
}

#pragma mark - Overridden getters and setters

- (NSString *)fileName
{
    if (!_fileName) {
        _fileName = [NSString stringWithFormat:@"Wellcore-%.0f", [NSDate date].timeIntervalSince1970];
    }
    return _fileName;
}

- (void)setFileName:(NSString *)fileName
{
    if (![_fileName isEqualToString:fileName]) {
        // Prevent appearance of files with empty names
        _fileName = fileName.length > 0 ? [fileName copy] : nil;
        _filePath = nil;
        _fileHandle = nil;
    }
}

- (NSString *)filePath
{
    if (!_filePath) {
        NSFileManager *fileManager = [NSFileManager new];
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *nameAndExt = [self.fileName stringByAppendingPathExtension:@"csv"];
        NSString *csvPath = [docsPath stringByAppendingPathComponent:nameAndExt];
        if (![fileManager fileExistsAtPath:csvPath]) {
            [fileManager createFileAtPath:csvPath contents:[NSData data] attributes:@{
                    NSFileProtectionKey: NSFileProtectionNone
            }];
        }
        _filePath = csvPath;
    }
    return _filePath;
}

- (NSFileHandle *)fileHandle
{
    if (!_fileHandle) {
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    }
    return _fileHandle;
}

#pragma mark - Implementation of the protocol

- (void)writeValues:(NSArray *)values
{
    typeof(self) __weak that = self;
    dispatch_async(self.ioQueue, ^{
        NSString *nextLine = [NSString stringWithFormat:@"%@;\n", [values componentsJoinedByString:@";"]];
        NSData *data = [nextLine dataUsingEncoding:NSUTF8StringEncoding];
        [that.fileHandle seekToEndOfFile];
        [that.fileHandle writeData:data];
    });
}

- (void)flushLogs
{
    typeof(self) __weak that = self;
    dispatch_sync(self.ioQueue, ^{
        [that.fileHandle synchronizeFile];
        [that.fileHandle closeFile];
    });
    _fileHandle = nil;
}

@end