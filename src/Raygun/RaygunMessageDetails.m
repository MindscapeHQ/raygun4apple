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

@implementation RaygunMessageDetails

@synthesize groupingKey    = _groupingKey;
@synthesize version        = _version;
@synthesize machineName    = _machineName;
@synthesize client         = _client;
@synthesize environment    = _environment;
@synthesize error          = _error;
@synthesize user           = _user;
@synthesize tags           = _tags;
@synthesize customData     = _customData;
@synthesize threads        = _threads;

-(void)setEnvironment:(RaygunEnvironmentMessage *)environment {
    _environment = environment;
}

-(void)setError:(RaygunErrorMessage *)error {
    _error = error;
}

-(void)setUser:(RaygunUserInformation *)user {
    _user = user;
}

-(void)setTags:(NSArray *)tags {
    _tags = tags;
}

-(void)setCustomData:(NSDictionary *)customData {
    _customData = customData;
}

-(void)setThreads:(NSArray<RaygunThread *> *)threads {
    _threads = threads;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: @{ @"version": _version }];
    
    if (_groupingKey) {
        dict[@"groupingKey"] = _groupingKey;
    }
    
    if (_machineName) {
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
    
    if (_tags) {
        dict[@"tags"] = _tags;
    }
    
    if (_customData) {
        dict[@"userCustomData"] = _customData;
    }
    
    if (_threads && _threads.count > 0) {
        NSMutableArray *threads = [NSMutableArray new];
        for (RaygunThread *thread in _threads) {
            [threads addObject:[thread convertToDictionary]];
        }
        dict[@"threads"] = threads;
    }
    
    if (_binaryImages && _binaryImages.count > 0) {
        NSMutableArray *binaryImages = [NSMutableArray new];
        for (RaygunBinaryImage *binaryImage in _binaryImages) {
            [binaryImages addObject:[binaryImage convertToDictionary]];
        }
        dict[@"binaryImages"] = binaryImages;
    }
    
    return dict;
}

@end
