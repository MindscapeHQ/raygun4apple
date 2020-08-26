//
//  RaygunBreadcrumb.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 10/10/18.
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

#import "RaygunBreadcrumb.h"

#import "RaygunUtils.h"
#import "NSError+Raygun_SimpleConstructor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RaygunBreadcrumb

+ (instancetype)breadcrumbWithBlock:(RaygunBreadcrumbBlock)block {
    return [[RaygunBreadcrumb alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(RaygunBreadcrumbBlock)block {
    NSParameterAssert(block);
    self = [super init];
    if (self) {
        // Set default values
        _timestamp = [RaygunUtils timeSinceEpochInMilliseconds];
        _type = RaygunBreadcrumbTypeManual;
        
        block(self);
    }
    
    return self;
}

+ (instancetype)breadcrumbWithInformation:(NSDictionary *)information {
    RaygunBreadcrumb *breadcrumb = [RaygunBreadcrumb breadcrumbWithBlock:^(RaygunBreadcrumb *breadcrumb) {
        breadcrumb.message    = information[@"message"];
        breadcrumb.category   = information[@"category"];
        breadcrumb.level      = [RaygunBreadcrumb levelEnumFromString:information[@"level"]];
        breadcrumb.type       = [RaygunBreadcrumb typeEnumFromString:information[@"type"]];
        breadcrumb.timestamp  = information[@"timestamp"];
        breadcrumb.className  = information[@"className"];
        breadcrumb.methodName = information[@"methodName"];
        breadcrumb.lineNumber = information[@"lineNumber"];
        breadcrumb.customData = information[@"customData"];
    }];
    return breadcrumb;
}

+ (enum RaygunBreadcrumbLevel)levelEnumFromString:(NSString *)level {
    static NSDictionary *levelDict = nil;
    if (levelDict == nil) {
        levelDict = @{ RaygunBreadcrumbLevelNames[RaygunBreadcrumbLevelDebug]:   [[NSNumber alloc] initWithInt:RaygunBreadcrumbLevelDebug],
                       RaygunBreadcrumbLevelNames[RaygunBreadcrumbLevelInfo]:    [[NSNumber alloc] initWithInt:RaygunBreadcrumbLevelInfo],
                       RaygunBreadcrumbLevelNames[RaygunBreadcrumbLevelWarning]: [[NSNumber alloc] initWithInt:RaygunBreadcrumbLevelWarning],
                       RaygunBreadcrumbLevelNames[RaygunBreadcrumbLevelError]:   [[NSNumber alloc] initWithInt:RaygunBreadcrumbLevelError] };
    }
    
    return [levelDict[level] intValue];
}

+ (enum RaygunBreadcrumbType)typeEnumFromString:(NSString *)type {
    static NSDictionary *typeDict = nil;
    if (typeDict == nil) {
        typeDict = @{ RaygunBreadcrumbTypeNames[RaygunBreadcrumbTypeManual]: [[NSNumber alloc] initWithInt:RaygunBreadcrumbTypeManual] };
    }
    
    return [typeDict[type] intValue];
}

+ (BOOL)validate:(nullable RaygunBreadcrumb *)breadcrumb withError:(NSError* __autoreleasing *)error {
    if (breadcrumb == nil) {
        [NSError fillError:error
                withDomain:[[self class] description]
                      code:0
               description:@"Breadcrumb cannot be nil"];
        return NO;
    }
    
    if ([RaygunUtils isNullOrEmpty:breadcrumb.message]) {
        [NSError fillError:error
                withDomain:[[self class] description]
                      code:0
               description:@"Breadcrumb message cannot be nil or empty"];
        return NO;
    }
    
    if (breadcrumb.timestamp == nil) {
        [NSError fillError:error
                withDomain:[[self class] description]
                      code:0
               description:@"Breadcrumb time stamp cannot be nil"];
        return NO;
    }
    
    return YES;
}

- (NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    dict[@"message"]   = _message;
    dict[@"level"]     = RaygunBreadcrumbLevelNames[_level];
    dict[@"type"]      = RaygunBreadcrumbTypeNames[_type];
    dict[@"timestamp"] = @([_timestamp longValue]);
    
    if (![RaygunUtils isNullOrEmpty:_category]) {
        dict[@"category"] = _category;
    }

    if (![RaygunUtils isNullOrEmpty:_className]) {
        dict[@"className"] = _className;
    }
    
    if (![RaygunUtils isNullOrEmpty:_methodName]) {
        dict[@"methodName"] = _methodName;
    }
    
    if (_lineNumber) {
        dict[@"lineNumber"] = _lineNumber;
    }
    
    if (![RaygunUtils isNullOrEmpty:_customData]) {
        dict[@"customData"] = _customData;
    }
    
    return dict;
}

@end

NS_ASSUME_NONNULL_END
