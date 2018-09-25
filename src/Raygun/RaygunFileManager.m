//
//  RaygunFileManager.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 21/09/18.
//

#import "RaygunFileManager.h"

#import "RaygunMessage.h"
#import "RaygunLogger.h"
#import "RaygunFile.h"

NSInteger const kMaxCrashReports = 64;

@interface RaygunFileManager ()

@property(nonatomic, copy) NSString *raygunPath;
@property(nonatomic, copy) NSString *crashesPath;
@property(nonatomic, assign) NSUInteger currentFileCounter;

@end

@implementation RaygunFileManager

+ (BOOL)createDirectoryAtPath:(NSString *)path withError:(NSError * __autoreleasing *)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error];
}

- (_Nullable instancetype)init {
    self = [super init];
    if (self) {
        // Get a hold of the file manager and the main directory to hold our files.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        
        // Create directory to hold all folders
        self.raygunPath = [cachePath stringByAppendingPathComponent:@"com.raygun"];
        if (![fileManager fileExistsAtPath:self.raygunPath]) {
            [self.class createDirectoryAtPath:self.raygunPath withError:nil];
        }
        
        // Create directory to hold all the crash reports.
        self.crashesPath = [self.raygunPath stringByAppendingPathComponent:@"crashes"];
        if (![fileManager fileExistsAtPath:self.raygunPath]) {
            [self.class createDirectoryAtPath:self.raygunPath withError:nil];
        }
        
        self.currentFileCounter = 0;
    }
    return self;
}

- (NSString *)storeCrashReport:(RaygunMessage *)message {
     return [self storeCrashReport:message maxCount:kMaxCrashReports];
}

- (NSString *)storeCrashReport:(RaygunMessage *)message maxCount:(NSUInteger)maxCount {
    @synchronized (self) {
        NSString *path = [self storeData:[message convertToJson] toPath:self.crashesPath];
        [self handleFileManagerLimit:self.crashesPath maxCount:MIN(maxCount, kMaxCrashReports)];
        return path;
    }
}

- (NSString *)storeData:(NSData *)data toPath:(NSString *)path {
    @synchronized (self) {
        NSString *finalPath = [path stringByAppendingPathComponent:[self uniqueAcendingJsonName]];
        [RaygunLogger logDebug:@"Saving message to disk: %@", finalPath];
        [data writeToFile:finalPath options:NSDataWritingAtomic error:nil];
        return finalPath;
    }
}

- (NSString *)uniqueAcendingJsonName {
    return [NSString stringWithFormat:@"%f-%lu-%@.json", [[NSDate date] timeIntervalSince1970], (unsigned long) self.currentFileCounter++, [NSUUID UUID].UUIDString];
}

- (NSArray<RaygunFile *> *)getAllStoredCrashReports {
    return [self allContentInFolder:self.crashesPath];
}

- (NSArray<RaygunFile *> *)allContentInFolder:(NSString *)path {
    @synchronized (self) {
        NSMutableArray *contents = [NSMutableArray new];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        for (NSString *filePath in [self allFilesInFolder:path]) {
            NSString *finalPath = [path stringByAppendingPathComponent:filePath];
            
            NSData *content = [fileManager contentsAtPath:finalPath];
            
            if (nil != content) {
                [contents addObject: [[RaygunFile alloc] initWithPath:finalPath withData:content]];
            }
        }
        return contents;
    }
}

- (NSArray<NSString *> *)allFilesInFolder:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    NSArray<NSString *> *storedFiles = [fileManager contentsOfDirectoryAtPath:path error:&error];
    
    if (nil != error) {
        [RaygunLogger logWarning:@"Couldn't load files in folder %@: %@", path, error];
        return [NSArray new];
    }
    
    // Sort the files to be in order in which to be sent.
    return [storedFiles sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (BOOL)removeFileAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    @synchronized (self) {
        [fileManager removeItemAtPath:path error:&error];
        
        if (nil != error) {
            [RaygunLogger logWarning:@"Couldn't delete file %@: %@", path, error];
            return NO;
        }
    }
    
    return YES;
}

- (void)handleFileManagerLimit:(NSString *)path maxCount:(NSUInteger)maxCount {
    NSArray<NSString *> *files = [self allFilesInFolder:path];
    NSInteger numbersOfFilesToRemove = ((NSInteger)files.count) - maxCount;
    
    if (numbersOfFilesToRemove > 0) {
        for (NSUInteger i = 0; i < numbersOfFilesToRemove; i++) {
            [self removeFileAtPath:[path stringByAppendingPathComponent:[files objectAtIndex:i]]];
        }
        [RaygunLogger logDebug:@"Removed %ld file(s) from <%@>", (long)numbersOfFilesToRemove, [path lastPathComponent]];
    }
}

@end
