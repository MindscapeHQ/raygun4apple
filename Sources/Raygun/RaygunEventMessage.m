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

#import "RaygunEventMessage.h"

#import "RaygunUserInformation.h"
#import "RaygunEventData.h"
#import "RaygunUtils.h"
#import "NSError+Raygun_SimpleConstructor.h"

@implementation RaygunEventMessage

+ (instancetype)messageWithBlock:(RaygunEventMessageBlock)block {
    return [[RaygunEventMessage alloc] initWithBlock:block];
}

- (instancetype)init {
    return [self initWithBlock:nil];
}

- (instancetype)initWithBlock:(RaygunEventMessageBlock)block {
    NSParameterAssert(block);
    self = [super init];
    if (self) {
        block(self);
    }
    
    return self;
}

- (NSData *)convertToJsonWithError:(NSError * __autoreleasing *)error {
    @try {
        NSMutableDictionary *message = [NSMutableDictionary dictionary];
        
        message[@"user"]      = [_userInformation convertToDictionary];
        message[@"type"]      = RaygunEventTypeNames[_eventType];
        message[@"sessionId"] = _sessionId;
        message[@"timestamp"] = _occurredOn;
        message[@"version"]   = [RaygunUtils isNullOrEmpty:_applicationVersion] ? kValueNotKnown : _applicationVersion;
        message[@"os"]        = [RaygunUtils isNullOrEmpty:_operatingSystem] ? kValueNotKnown : _operatingSystem;
        message[@"osVersion"] = [RaygunUtils isNullOrEmpty:_osVersion] ? kValueNotKnown : _osVersion;
        message[@"platform"]  = [RaygunUtils isNullOrEmpty:_platform] ? kValueNotKnown : _platform;
        
        if (_eventData != nil) {
            // The current format requires the data to be translated to a string.
            NSArray   *dataArray = @[[_eventData convertToDictionary]];
            NSData    *eventData = [NSJSONSerialization dataWithJSONObject:dataArray options:0 error:nil];
            NSString *dataString = [[NSString alloc] initWithData:eventData encoding:NSUTF8StringEncoding];
            message[@"data"] = dataString;
        }
        
        NSData *json = [NSJSONSerialization dataWithJSONObject:@{@"eventData":@[message]} options:0 error:nil];
        
        return json;
    } @catch (NSException *exception) {
        [NSError fillError:error withDomain:[[self class] description] code:0 description:@"Exception occurred: %@", exception.description];
    }
    
    return nil;
}

@end
