//
//  RaygunMessageDetails.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 11/09/17.
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

#import "RaygunMessageDetails.h"

#import "RaygunDefines.h"
#import "RaygunClientMessage.h"
#import "RaygunEnvironmentMessage.h"
#import "RaygunErrorMessage.h"
#import "RaygunUserInformation.h"
#import "RaygunThread.h"
#import "RaygunBinaryImage.h"

@implementation RaygunMessageDetails

- (NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: @{ @"version": _version }];
    
    if (!IsNullOrEmpty(_groupingKey)) {
        dict[@"groupingKey"] = _groupingKey;
    }
    
    if (!IsNullOrEmpty(_machineName)) {
        dict[@"machineName"] = _machineName;
    }
    
    if (_client) {
        dict[@"client"] = [_client convertToDictionary];
    }
    
    if (_environment) {
        dict[@"environment"] = [_environment convertToDictionary];
    }
    
    if (_error) {
        dict[@"error"] = [_error convertToDictionary];
    }
    
    if (_user) {
        dict[@"user"] = [_user convertToDictionary];
    }
    
    if (!IsNullOrEmpty(_tags)) {
        dict[@"tags"] = _tags;
    }
    
    if (!IsNullOrEmpty(_customData)) {
        dict[@"userCustomData"] = _customData;
    }
    
    if (!IsNullOrEmpty(_threads)) {
        NSMutableArray *threads = [NSMutableArray new];
        for (RaygunThread *thread in _threads) {
            [threads addObject:[thread convertToDictionary]];
        }
        dict[@"threads"] = threads;
    }
    
    if (!IsNullOrEmpty(_binaryImages)) {
        NSMutableArray *binaryImages = [NSMutableArray new];
        for (RaygunBinaryImage *binaryImage in _binaryImages) {
            [binaryImages addObject:[binaryImage convertToDictionary]];
        }
        dict[@"binaryImages"] = binaryImages;
    }
    
    return dict;
}

@end
