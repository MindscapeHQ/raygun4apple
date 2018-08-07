//
//  RaygunMessageDetails.m
//  Raygun4iOS
//
//  Created by Mitchell Duncan on 11/09/17.
//  Copyright © 2017 Mindscape. All rights reserved.
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
@synthesize userCustomData = _userCustomData;
@synthesize threads        = _threads;

-(void)setEnvironment:(RaygunEnvironmentMessage *)environment {
    _environment = environment;
}

-(void)setError:(RaygunErrorMessage *)error {
    _error = error;
}

-(void)setUser:(RaygunUserInfo *)user {
    _user = user;
}

-(void)setTags:(NSArray *)tags {
    _tags = tags;
}

-(void)setUserCustomData:(NSDictionary *)userCustomData {
    _userCustomData = userCustomData;
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
    
    if (_userCustomData) {
        dict[@"userCustomData"] = _userCustomData;
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
