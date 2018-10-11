//
//  RaygunBreadcrumb.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 10/10/18.
//

#import "RaygunBreadcrumb.h"

#import "RaygunUtils.h"

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
        block(self);
    }
    
    return self;
}

- (NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    dict[@"message"]   = _message;
    dict[@"level"]     = RaygunBreadcrumbLevelNames[_level];
    dict[@"type"]      = RaygunBreadcrumbTypeNames[_type];
    dict[@"timeStamp"] = _occurredOn;
    
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
