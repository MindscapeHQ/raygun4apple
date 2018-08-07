//
//  RaygunUserInfo.m
//  Raygun4iOS
//
//  Created by Jason Fauchelle on 16/06/15.
//  Copyright (c) 2015 Mindscape. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RaygunUserInfo.h"

@implementation RaygunUserInfo

@synthesize identifier  = _identifier;
@synthesize uuid        = _uuid;
@synthesize isAnonymous = _isAnonymous;
@synthesize email       = _email;
@synthesize fullName    = _fullName;
@synthesize firstName   = _firstName;

- (id)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier withEmail:nil withFullName:nil withFirstName:nil];
}

- (id)initWithIdentifier:(NSString *)identifier
               withEmail:(NSString *)email
            withFullName:(NSString *)fullName
           withFirstName:(NSString *)firstName {
    return [self initWithIdentifier:identifier withEmail:email withFullName:fullName withFirstName:firstName withIsAnonymous:NO];
}

- (id)initWithIdentifier:(NSString *)identifier
               withEmail:(NSString *)email
            withFullName:(NSString *)fullName
           withFirstName:(NSString *)firstName
         withIsAnonymous:(BOOL)isAnonymous {
    return [self initWithIdentifier:identifier withEmail:email withFullName:fullName withFirstName:firstName withIsAnonymous:isAnonymous withUuid:nil];
}

- (id)initWithIdentifier:(NSString *)identifier
               withEmail:(NSString *)email
            withFullName:(NSString *)fullName
           withFirstName:(NSString *)firstName
         withIsAnonymous:(BOOL)isAnonymous
                withUuid:(NSString *)uuid {
    if ((self = [super init])) {
        self.identifier  = identifier;
        self.email       = email;
        self.fullName    = fullName;
        self.firstName   = firstName;
        self.isAnonymous = isAnonymous;
        self.uuid        = uuid;
    }
    return self;
}

-(NSDictionary * )convertToDictionary {
    NSMutableDictionary *details = [NSMutableDictionary dictionaryWithDictionary:@{@"isAnonymous":_isAnonymous?@YES:@NO}];
    
    if (_identifier) {
        details[@"identifier"] = _identifier;
    }
    if (_email) {
        details[@"email"] = _email;
    }
    if (_fullName) {
        details[@"fullName"] = _fullName;
    }
    if (_firstName) {
        details[@"firstName"] = _firstName;
    }
    if (_uuid) {
        details[@"uuid"] = _uuid;
    }
    
    return details;
}

@end
