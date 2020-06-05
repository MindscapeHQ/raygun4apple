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

#import "RaygunClientMessage.h"
#import "RaygunEnvironmentMessage.h"
#import "RaygunErrorMessage.h"
#import "RaygunUserInformation.h"
#import "RaygunThread.h"
#import "RaygunBinaryImage.h"
#import "RaygunBreadcrumb.h"
#import "RaygunUtils.h"
#import "RaygunDefines.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RaygunMessageDetails

- (NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    dict[@"version"] = [RaygunUtils isNullOrEmpty:_version] ? kValueNotKnown : _version;
    
    if (![RaygunUtils isNullOrEmpty:_groupingKey]) {
        dict[@"groupingKey"] = _groupingKey;
    }
    
    if (![RaygunUtils isNullOrEmpty:_machineName]) {
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
    
    if (![RaygunUtils isNullOrEmpty:_tags]) {
        dict[@"tags"] = _tags;
    }
    
    if (![RaygunUtils isNullOrEmpty:_customData]) {
        dict[@"userCustomData"] = _customData;
    }
    
    if (![RaygunUtils isNullOrEmpty:_threads]) {
        NSMutableArray *threads = [NSMutableArray array];
        for (RaygunThread *thread in _threads) {
            [threads addObject:[thread convertToDictionary]];
        }
        dict[@"threads"] = threads;
    }
    
    if (![RaygunUtils isNullOrEmpty:_binaryImages ]) {
        NSMutableArray *binaryImages = [NSMutableArray array];
        for (RaygunBinaryImage *binaryImage in _binaryImages) {
            [binaryImages addObject:[binaryImage convertToDictionary]];
        }
        dict[@"binaryImages"] = binaryImages;
    }
    
    if (![RaygunUtils isNullOrEmpty:_breadcrumbs]) {
        NSMutableArray *breadcrumbs = [NSMutableArray array];
        for (RaygunBreadcrumb *breadcrumb in _breadcrumbs) {
            [breadcrumbs addObject:[breadcrumb convertToDictionary]];
        }
        dict[@"breadcrumbs"] = breadcrumbs;
    }
    
    return dict;
}

@end

NS_ASSUME_NONNULL_END
