//
//  RaygunClientMessage.m
//  Raygun4iOS
//
//  Created by Mitchell Duncan on 11/09/17.
//  Copyright © 2017 Mindscape. All rights reserved.
//

#import "RaygunClientMessage.h"

@implementation RaygunClientMessage

@synthesize name = _name;
@synthesize version = _version;
@synthesize clientUrl = _clientUrl;

- (id)init:(NSString *)name withVersion:(NSString *)version withUrl:(NSString *)url {
    if ((self = [super init])) {
        self.name = name;
        self.version = version;
        self.clientUrl = url;
    }
    
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (_name) {
        dict[@"name"] = _name;
    }
    
    if (_version) {
        dict[@"version"] = _version;
    }
    
    if (_clientUrl) {
        dict[@"clientUrl"] = _clientUrl;
    }
    
    return dict;
}

@end
