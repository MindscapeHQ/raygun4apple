//
//  RaygunUserInformations.m
//  raygun4apple
//
//  Created by Jason Fauchelle on 16/06/15.
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

#import "RaygunUserInformation.h"

#import "RaygunDefines.h"

static RaygunUserInformation *sharedAnonymousUser = nil;

@implementation RaygunUserInformation

+ (RaygunUserInformation *)anonymousUser {
    if (sharedAnonymousUser == nil) {
        sharedAnonymousUser = [[RaygunUserInformation alloc] initWithIdentifier:[RaygunUserInformation anonymousIdentifier]];
        sharedAnonymousUser.isAnonymous = @YES;
    }
    return sharedAnonymousUser;
}

+ (NSString *)anonymousIdentifier {
    // Check if we have stored one before
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *identifier = [defaults stringForKey:kRaygunIdentifierUserDefaultsKey];
    
    if (!identifier) {
        if ([UIDevice.currentDevice respondsToSelector:@selector(identifierForVendor)]) {
            identifier = UIDevice.currentDevice.identifierForVendor.UUIDString;
        }
        else {
            CFUUIDRef theUUID = CFUUIDCreate(NULL);
            identifier = (__bridge NSString *)CFUUIDCreateString(NULL, theUUID);
            CFRelease(theUUID);
        }
        
        // Store the identifier
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:identifier forKey:kRaygunIdentifierUserDefaultsKey];
        [defaults synchronize];
    }
    
    return identifier;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier withEmail:nil withFullName:nil withFirstName:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                         withEmail:(NSString *)email
                      withFullName:(NSString *)fullName
                     withFirstName:(NSString *)firstName {
    return [self initWithIdentifier:identifier withEmail:email withFullName:fullName withFirstName:firstName withIsAnonymous:NO];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                         withEmail:(NSString *)email
                      withFullName:(NSString *)fullName
                     withFirstName:(NSString *)firstName
                   withIsAnonymous:(BOOL)isAnonymous {
    return [self initWithIdentifier:identifier withEmail:email withFullName:fullName withFirstName:firstName withIsAnonymous:isAnonymous withUuid:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
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

- (NSDictionary *)convertToDictionary {
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
