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
        _type = kRaygunBreadcrumbTypeManual;
        
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

+ (RaygunBreadcrumbLevel)levelEnumFromString:(NSString *)level {
    static NSDictionary *levelDict = nil;
    if (levelDict == nil) {
        levelDict = @{ RaygunBreadcrumbLevelNames[kRaygunBreadcrumbLevelDebug]:   [[NSNumber alloc] initWithInt:kRaygunBreadcrumbLevelDebug],
                       RaygunBreadcrumbLevelNames[kRaygunBreadcrumbLevelInfo]:    [[NSNumber alloc] initWithInt:kRaygunBreadcrumbLevelInfo],
                       RaygunBreadcrumbLevelNames[kRaygunBreadcrumbLevelWarning]: [[NSNumber alloc] initWithInt:kRaygunBreadcrumbLevelWarning],
                       RaygunBreadcrumbLevelNames[kRaygunBreadcrumbLevelError]:   [[NSNumber alloc] initWithInt:kRaygunBreadcrumbLevelError] };
    }
    
    return [levelDict[level] intValue];
}

+ (RaygunBreadcrumbType)typeEnumFromString:(NSString *)type {
    static NSDictionary *typeDict = nil;
    if (typeDict == nil) {
        typeDict = @{ RaygunBreadcrumbTypeNames[kRaygunBreadcrumbTypeManual]: [[NSNumber alloc] initWithInt:kRaygunBreadcrumbTypeManual] };
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
    
    if (![RaygunUtils IsNullOrEmpty:_category]) {
        dict[@"category"] = _category;
    }

    if (![RaygunUtils IsNullOrEmpty:_className]) {
        dict[@"className"] = _className;
    }
    
    if (![RaygunUtils IsNullOrEmpty:_methodName]) {
        dict[@"methodName"] = _methodName;
    }
    
    if (_lineNumber) {
        dict[@"lineNumber"] = _lineNumber;
    }
    
    if (![RaygunUtils IsNullOrEmpty:_customData]) {
        dict[@"customData"] = _customData;
    }
    
    return dict;
}

@end
