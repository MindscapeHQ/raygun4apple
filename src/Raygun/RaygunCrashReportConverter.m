//
//  RaygunCrashReportConverter.m
//  raygun4apple
//
//  Created by raygundev on 8/1/18.
//  Copyright © 2018 Raygun Limited. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>

#import "RaygunDefines.h"

#if RAYGUN_CAN_USE_UIKIT
#import <UIKit/UIKit.h>
#endif

#import "RaygunCrashReportConverter.h"
#import "RaygunMessage.h"

@interface RaygunCrashReportConverter ()

@end

@implementation RaygunCrashReportConverter

- (RaygunMessage *)convertReportToMessage:(NSDictionary *)report {
    NSString *occurredOn = [self occurredOn:report];
    RaygunMessageDetails *details = [self messageDetailsFromReport:report];
    RaygunMessage *message = [[RaygunMessage alloc] init:occurredOn withDetails:details];
    
    return message;
}

- (NSString *)occurredOn:(NSDictionary *)report {
    NSString *occurredOn = report[@"report"][@"timestamp"];
    
    if (occurredOn == nil) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [dateFormatter setTimeZone:utcTimeZone];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setLocale:locale];
        
        occurredOn = [dateFormatter stringFromDate:[NSDate date]];
    }
    
    return occurredOn;
}

- (RaygunMessageDetails *)messageDetailsFromReport:(NSDictionary *)report {
    RaygunMessageDetails *details = [[RaygunMessageDetails alloc] init];
    
    // Application Version
    details.version = [self applicationVersionFromCrashReport:report];
    
    // Raygun Client
    RaygunClientMessage *client = [self clientInfoFromCrashReport:report];
    details.client = client;
    
    // Environment
    RaygunEnvironmentMessage *env = [self environmentDetailsFromCrashReport:report];
    details.environment = env;
    
    // Error
    RaygunErrorMessage *error = [self errorDetailsFromCrashReport:report];
    details.error = error;
    
    // Threads
    NSArray<RaygunThread *> *threads = [self threadsFromCrashReport:report];
    details.threads = threads;
    
    // Binaries
    NSArray<RaygunBinaryImage *> *binaryImages = [self referencedBinaryImagesFromCrashReport:report threads:threads];
    details.binaryImages = binaryImages;
    
    // Machine Name
    #if RAYGUN_CAN_USE_UIDEVICE
    details.machineName = [[UIDevice currentDevice] name];
    #endif
    
    // User, Tags & Custom Data
    NSDictionary *userData = report[@"user"];
    if (userData != nil) {
        RaygunUserInformation *user = [self userInfoFromCrashReportUserData:userData];
        details.user = user;
        
        if (userData[@"tags"]) {
            details.tags = userData[@"tags"];
        }
        
        if (userData[@"customData"]) {
            details.customData = userData[@"customData"];
        }
    }
    
    return details;
}

- (NSString *)applicationVersionFromCrashReport:(NSDictionary *)report {
    NSString *appVersion = report[@"user"][@"applicationVersion"];
    
    if (appVersion == nil) {
        appVersion = report[@"system"][@"CFBundleShortVersionString"];
    }
    
    if (appVersion == nil) {
        appVersion = @"Unknown";
    }
    return appVersion;
}

- (RaygunClientMessage *)clientInfoFromCrashReport:(NSDictionary *)report {
    NSString *clientName    = @"Raygun4Apple";
    NSString *clientUrl     = @"https://github.com/mindscapehq/raygun4apple";
    NSString *clientVersion = @"1.0.0 beta 2";
    
    return [[RaygunClientMessage alloc] init:clientName withVersion:clientVersion withUrl:clientUrl];
}

- (RaygunEnvironmentMessage *)environmentDetailsFromCrashReport:(NSDictionary *)report {
    RaygunEnvironmentMessage *environment = [[RaygunEnvironmentMessage alloc] init];
    
    NSDictionary *systemData = report[@"system"];
    
    NSString *osVersion = [NSString stringWithFormat:@"%@ %@ (%@)",
                           systemData[@"system_name"],
                           systemData[@"system_version"],
                           systemData[@"os_version"]];
    
    if (!osVersion) {
        osVersion = @"Unknown";
    }
    
    NSLocale *locale = [NSLocale currentLocale];
    NSString *localeStr = [locale displayNameForKey:NSLocaleIdentifier value: [locale localeIdentifier]];
    
    if (!localeStr) {
        localeStr = [locale localeIdentifier];
    }
    
    if (!localeStr) {
        localeStr = @"Unknown";
    }
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    environment.processorCount     = nil;
    environment.oSVersion          = osVersion;
    environment.model              = systemData[@"machine"];
    environment.windowsBoundWidth  = @(screenBounds.size.width);
    environment.windowsBoundHeight = @(screenBounds.size.height);
    environment.resolutionScale    = @([[UIScreen mainScreen] scale]);
    environment.cpu                = systemData[@"cpu_arch"];
    environment.utcOffset          = @([[NSTimeZone systemTimeZone] secondsFromGMT] / 3600);
    environment.locale             = localeStr;
    environment.kernelVersion      = systemData[@"kernel_version"];
    environment.memorySize         = systemData[@"memory"][@"size"];
    environment.memoryFree         = systemData[@"memory"][@"free"];
    environment.jailBroken         = [systemData[@"jailbroken"] boolValue];
    
    return environment;
}

- (RaygunErrorMessage *)errorDetailsFromCrashReport:(NSDictionary *)report {
    
    NSDictionary *errorData  = report[@"crash"][@"error"];
    NSString     *diagnosis  = report[@"crash"][@"diagnosis"];
    NSString     *signalName = @"Unknown";
    NSString     *signalCode = @"Unknown";
    NSString     *className  = @"Unknown";
    NSString     *message    = nil;
    
    if (errorData != nil) {
        NSString *exceptionType = errorData[@"type"];
        
        if ([exceptionType isEqualToString:@"nsexception"]) {
            message   = errorData[@"nsexception"][@"reason"];
            className = errorData[@"nsexception"][@"name"];
        }
        else if ([exceptionType isEqualToString:@"cpp_exception"]) {
            message   = errorData[@"cpp_exception"][@"name"];
            className = @"C++ Exception";
        }
        else if ([exceptionType isEqualToString:@"mach"]) {
            message = [NSString stringWithFormat:@"Exception %@, Code %@, Subcode %@",
                       [self nullCoalesce:errorData[@"mach"] withProperty:@"exception_name" withFallback:@"exception"],
                       [self nullCoalesce:errorData[@"mach"] withProperty:@"code_name" withFallback:@"code"], errorData[@"mach"][@"subcode"]];
            className  = errorData[@"mach"][@"exception_name"];
            signalCode = [self nullCoalesce:errorData[@"signal"] withProperty:@"code_name" withFallback:@"code"];
            signalName = errorData[@"signal"][@"name"];
        }
        else if ([exceptionType isEqualToString:@"signal"]) {
            signalCode = [self nullCoalesce:errorData[@"signal"] withProperty:@"code_name" withFallback:@"code"];
            signalName = errorData[@"signal"][@"name"];
            message    = [NSString stringWithFormat:@"Signal %@, Code %@", signalName, signalCode];
            className  = errorData[@"mach"][@"exception_name"];
        }
        else if ([exceptionType isEqualToString:@"deadlock"]) {
            message = @"Deadlock";
        }
        else if ([exceptionType isEqualToString:@"user"]) {
            message   = errorData[@"reason"];
            className = errorData[@"user_reported"][@"name"];
        }
        
        if (message == nil && (diagnosis == nil || diagnosis.length == 0)) {
            // No message and no diagnosis either
            message = @"Unknown";
        }
        else if (message == nil && diagnosis != nil && diagnosis.length > 0) {
            // No message but we have a diagnosis
            message = diagnosis;
        }
        else if (message != nil && diagnosis != nil && diagnosis.length > 0) {
            // We have a message and diagnosis so append them
            message = [message stringByAppendingString:[NSString stringWithFormat:@" \n%@", diagnosis]];
        }
    }
    
    return [[RaygunErrorMessage alloc] init:className withMessage:message withSignalName:signalName withSignalCode:signalCode withStackTrace:nil];
}

- (NSString *)nullCoalesce:(NSDictionary *)data withProperty:(NSString *)property withFallback:(NSString *) fallback {
    return [data objectForKey:property] ? [data objectForKey:property] : [data objectForKey:fallback];
}

- (RaygunUserInformation *)userInfoFromCrashReportUserData:(NSDictionary *)userData {
    NSDictionary *userInfo = userData[@"userInfo"];
    
    if (userInfo != nil) {
        return [[RaygunUserInformation alloc] initWithIdentifier:userInfo[@"identifier"]
                                                       withEmail:userInfo[@"email"]
                                                    withFullName:userInfo[@"fullName"]
                                                   withFirstName:userInfo[@"firstName"]
                                                 withIsAnonymous:[userInfo[@"isAnonymous"] boolValue]
                                                        withUuid:userInfo[@"uuid"]];
    }
    
    return nil;
}

- (NSArray *)referencedBinaryImagesFromCrashReport:(NSDictionary *)report threads:(NSArray<RaygunThread *> *)threads {
    NSArray *binaryImageData = report[@"binary_images"];
    NSMutableArray *raygunBinaryImages = [NSMutableArray new];
    
    for (NSDictionary *binaryImage in binaryImageData) {
        if ([self isBinaryImageReferenced:binaryImage threads:threads]) {
            RaygunBinaryImage *raygunBinaryImage = [[RaygunBinaryImage alloc] initWithUuId:binaryImage[@"uuid"]
                                                                                  withName:binaryImage[@"name"]
                                                                               withCpuType:binaryImage[@"cpu_type"]
                                                                            withCpuSubType:binaryImage[@"cpu_subtype"]
                                                                          withImageAddress:binaryImage[@"image_addr"]
                                                                             withImageSize:binaryImage[@"image_size"]];
            
            [raygunBinaryImages addObject:raygunBinaryImage];
        }
    }
    
    return raygunBinaryImages;
}

- (BOOL)isBinaryImageReferenced:(NSDictionary *)binaryImage threads:(NSArray<RaygunThread *> *)threads {
    uintptr_t imageStart = (uintptr_t) [binaryImage[@"image_addr"] unsignedLongLongValue];
    uintptr_t imageEnd = imageStart + (uintptr_t) [binaryImage[@"image_size"] unsignedLongLongValue];
    
    for (RaygunThread *thread in threads) {
        for (RaygunFrame *frame in thread.frames) {
            uintptr_t address = frame.instructionAddress.longValue;
            if (address >= imageStart && address < imageEnd) {
                // binary image is referenced
                return true;
            }
        }
    }
    
    return false;
}

- (NSArray *)threadsFromCrashReport:(NSDictionary *)report {
    NSArray *threadData = report[@"crash"][@"threads"];
    NSMutableArray *raygunThreads = [NSMutableArray new];
    
    for (NSDictionary *thread in threadData) {
        RaygunThread *raygunThread = [[RaygunThread alloc] init:thread[@"index"]];
        raygunThread.frames  = [self stackFramesForThread:thread];
        raygunThread.crashed = [thread[@"crashed"] boolValue];
        raygunThread.current = [thread[@"current_thread"] boolValue];
        raygunThread.name    = thread[@"name"];
        if (raygunThread.name == nil) {
            raygunThread.name = thread[@"dispatch_queue"];
        }
        
        [raygunThreads addObject:raygunThread];
    }
    
    return raygunThreads;
}

- (NSArray<RaygunFrame *> *)stackFramesForThread:(NSDictionary *)thread {
    NSArray *frameData = thread[@"backtrace"][@"contents"];
    NSUInteger frameCount = frameData.count;
    if (frameCount <= 0) {
        return [NSArray new];
    }
    
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:frameCount];
    for (NSInteger i = frameCount - 1; i >= 0; i--) {
        [frames addObject:[self stackFrameFromFrameData:[frameData objectAtIndex:i]]];
    }
    return frames;
}

- (RaygunFrame *)stackFrameFromFrameData:(NSDictionary *)frameData {
    RaygunFrame *frame = [[RaygunFrame alloc] init];
    frame.symbolAddress = frameData[@"symbol_addr"];
    frame.instructionAddress = frameData[@"instruction_addr"];
    if (frameData[@"symbol_name"]) {
        frame.symbolName = frameData[@"symbol_name"];
    }
    return frame;
}

@end

