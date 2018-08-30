//
//  RaygunEventMessage.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 29/08/18.
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

#import "RaygunEventMessage.h"
#import "RaygunUserInformation.h"
#import "RaygunEventData.h"

@implementation RaygunEventMessage

@synthesize occurredOn      = _occurredOn;
@synthesize sessionId       = _sessionId;
@synthesize eventType       = _eventType;
@synthesize userInformation = _userInformation;
@synthesize version         = _version;
@synthesize operatingSystem = _operatingSystem;
@synthesize osVersion       = _osVersion;
@synthesize platform        = _platform;
@synthesize eventData       = _eventData;


/* TODO: Setters
 @"osVersion": osVersion != nil ? osVersion : @"",
 @"platform": platform != nil ? platform : @"",
 */

+ (instancetype)messageWithBlock:(RaygunEventMessageBlock)block;
{
    return [[self alloc] initWithBlock:block];
}

- (instancetype)init;
{
    return [self initWithBlock:nil];
}

- (instancetype)initWithBlock:(RaygunEventMessageBlock)block;
{
    NSParameterAssert(block);
    self = [super init];
    if (self) {
        block(self);
    }
    
    return self;
}

- (NSData *)convertToJson {
    NSMutableDictionary *message = [NSMutableDictionary new];
    
    [message setValue:[_userInformation convertToDictionary] forKey:@"user"];
    [message setValue:RaygunEventTypeNames[_eventType]       forKey:@"type"];
    [message setValue:_sessionId       forKey:@"sessionId"];
    [message setValue:_occurredOn      forKey:@"timestamp"];
    [message setValue:_version         forKey:@"version"];
    [message setValue:_operatingSystem forKey:@"os"];
    [message setValue:_osVersion       forKey:@"osVersion"];
    [message setValue:_platform        forKey:@"platform"];

    if (_eventData != nil) {
        [message setValue:@[[_eventData convertToDictionary]] forKey:@"data"];
    }
    
    return [NSJSONSerialization dataWithJSONObject:@{@"eventData":@[message]} options:0 error:nil];
}

@end
