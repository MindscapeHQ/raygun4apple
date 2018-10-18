//
//  RaygunEventMessage.h
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

#ifndef RaygunEventMessage_h
#define RaygunEventMessage_h

#import <Foundation/Foundation.h>

#import "RaygunDefines.h"

@class RaygunEventMessage, RaygunUserInformation, RaygunEventData;

typedef void(^RaygunEventMessageBlock)(RaygunEventMessage *message);

@interface RaygunEventMessage : NSObject

@property (nonatomic, copy)   NSString *occurredOn;
@property (nonatomic, copy)   NSString *sessionId;
@property (nonatomic) enum    RaygunEventType eventType;
@property (nonatomic, strong) RaygunUserInformation *userInformation;
@property (nonatomic, copy)   NSString *applicationVersion;
@property (nonatomic, copy)   NSString *operatingSystem;
@property (nonatomic, copy)   NSString *osVersion;
@property (nonatomic, copy)   NSString *platform;
@property (nonatomic, strong) RaygunEventData *eventData;

+ (instancetype)messageWithBlock:(RaygunEventMessageBlock)block;
- (instancetype)initWithBlock:(RaygunEventMessageBlock)block NS_DESIGNATED_INITIALIZER;

/*
 * Creates and returns the json payload to be sent to Raygun.
 *
 * @return a data object containing the RaygunEventMessage properties in a json format.
 */
- (NSData *)convertToJsonWithError:(NSError **)error;

@end

#endif /* RaygunEventMessage_h */
