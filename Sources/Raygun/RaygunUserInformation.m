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

#if RAYGUN_CAN_USE_UIDEVICE
#import <UIKit/UIKit.h>
#endif

#import "RaygunUtils.h"
#import "NSError+Raygun_SimpleConstructor.h"

NS_ASSUME_NONNULL_BEGIN

static RaygunUserInformation *sharedAnonymousUser = nil;
static NSString *sharedUuid = nil;

@implementation RaygunUserInformation

+ (RaygunUserInformation *)anonymousUser {
    if (sharedAnonymousUser == nil) {
        sharedAnonymousUser = [[RaygunUserInformation alloc] initWithIdentifier:[RaygunUserInformation UUID]];
        sharedAnonymousUser.isAnonymous = YES;
    }
    return sharedAnonymousUser;
}

+ (NSString *)UUID {
    if (sharedUuid == nil) {
        // Check if we have stored one before
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        sharedUuid = [defaults stringForKey:kRaygunIdentifierUserDefaultsKey];
        
        if (!sharedUuid) {
            sharedUuid = [self generateIdentifier];
            
            // Store the identifier
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:sharedUuid forKey:kRaygunIdentifierUserDefaultsKey];
            [defaults synchronize];
        }
    }
    
    return sharedUuid;
}

+ (NSString *)generateIdentifier {
    NSString *identifier = nil;
    
    #if RAYGUN_CAN_USE_UIDEVICE
    if ([UIDevice.currentDevice respondsToSelector:@selector(identifierForVendor)]) {
        identifier = UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
    else {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        identifier = (__bridge NSString *)CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
    }
    #else
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    identifier = (__bridge NSString *)CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    #endif
    
    return identifier;
}

+ (BOOL)validate:(nullable RaygunUserInformation *)userInformation withError:(NSError * __autoreleasing *)error {
    if (userInformation == nil) {
        [NSError fillError:error
                withDomain:[[self class] description]
                      code:0
               description:@"The RaygunUserInformation object cannot be nil"];
        return NO;
    }
    
    if ([RaygunUtils isNullOrEmpty:userInformation.identifier]) {
        [NSError fillError:error
                withDomain:[[self class] description]
                      code:0
               description:@"The user identifier cannot be nil or empty"];
        return NO;
    }
    
    return YES;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier
                          withEmail:nil
                       withFullName:nil
                      withFirstName:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                         withEmail:(nullable NSString *)email
                      withFullName:(nullable NSString *)fullName
                     withFirstName:(nullable NSString *)firstName {
    return [self initWithIdentifier:identifier
                          withEmail:email
                       withFullName:fullName
                      withFirstName:firstName
                    withIsAnonymous:NO];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                         withEmail:(nullable NSString *)email
                      withFullName:(nullable NSString *)fullName
                     withFirstName:(nullable NSString *)firstName
                   withIsAnonymous:(BOOL)isAnonymous {
    return [self initWithIdentifier:identifier
                          withEmail:email
                       withFullName:fullName
                      withFirstName:firstName
                    withIsAnonymous:isAnonymous
                           withUuid:[RaygunUserInformation UUID]];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                         withEmail:(nullable NSString *)email
                      withFullName:(nullable NSString *)fullName
                     withFirstName:(nullable NSString *)firstName
                   withIsAnonymous:(BOOL)isAnonymous
                          withUuid:(nullable NSString *)uuid {
    if ((self = [super init])) {
        _identifier  = identifier;
        _email       = email;
        _fullName    = fullName;
        _firstName   = firstName;
        _isAnonymous = isAnonymous;
        _uuid        = uuid;
    }
    return self;
}

- (NSDictionary *)convertToDictionary {
    NSMutableDictionary *details = [NSMutableDictionary dictionaryWithDictionary:@{@"isAnonymous":_isAnonymous?@"True":@"False"}];
    
    if (![RaygunUtils isNullOrEmpty:_identifier]) {
        details[@"identifier"] = _identifier;
    }
    
    if (![RaygunUtils isNullOrEmpty:_email]) {
        details[@"email"] = _email;
    }
    
    if (![RaygunUtils isNullOrEmpty:_fullName]) {
        details[@"fullName"] = _fullName;
    }
    
    if (![RaygunUtils isNullOrEmpty:_firstName]) {
        details[@"firstName"] = _firstName;
    }
    
    if (![RaygunUtils isNullOrEmpty:_uuid]) {
        details[@"uuid"] = _uuid;
    }
    
    return details;
}

@end

NS_ASSUME_NONNULL_END
