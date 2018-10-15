//
//  RaygunBreadcrumb.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 10/10/18.
//

#import "RaygunBreadcrumb.h"

#import "RaygunUtils.h"
#import "NSError+SimpleConstructor.h"

@implementation RaygunBreadcrumb

+ (instancetype)breadcrumbWithBlock:(RaygunBreadcrumbBlock)block {
    return [[RaygunBreadcrumb alloc] initWithBlock:block];
}

- (instancetype)init {
    return [self initWithBlock:nil];
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

+ (BOOL)validate:(RaygunBreadcrumb *)breadcrumb withError:(NSError* __autoreleasing *)error {
    if (breadcrumb == nil) {
        [NSError fillError:error
                withDomain:[[self class] description]
                      code:0
               description:@"Breadcrumb cannot be nil"];
        return NO;
    }
    
    if ([RaygunUtils isNullOrEmptyString:breadcrumb.message]) {
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
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    dict[@"message"]   = _message;
    dict[@"level"]     = RaygunBreadcrumbLevelNames[_level];
    dict[@"type"]      = RaygunBreadcrumbTypeNames[_type];
    dict[@"timestamp"] = @([_timestamp longValue]);
    
    if (![RaygunUtils isNullOrEmptyString:_category]) {
        dict[@"category"] = _category;
    }

    if (![RaygunUtils isNullOrEmptyString:_className]) {
        dict[@"className"] = _className;
    }
    
    if (![RaygunUtils isNullOrEmptyString:_methodName]) {
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
