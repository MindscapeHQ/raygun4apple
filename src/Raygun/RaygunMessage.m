//
//  RaygunMessage.m
//  Raygun4iOS
//
//  Created by Mitchell Duncan on 11/09/17.
//  Copyright © 2017 Mindscape. All rights reserved.
//

#import "RaygunMessage.h"

@implementation RaygunMessage

@synthesize occurredOn = _occurredOn;
@synthesize details    = _details;

- (id)init:(NSString *)occurredOn withDetails:(RaygunMessageDetails *)details
{
    if ((self = [super init])) {
        self.occurredOn = occurredOn;
        self.details = details;
    }
    
    return self;
}

- (NSData *)convertToJson
{
    NSMutableDictionary *report = [NSMutableDictionary dictionaryWithDictionary: @{ @"occurredOn": _occurredOn, @"details": [_details convertToDictionary] }];
    return [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];
}

@end
