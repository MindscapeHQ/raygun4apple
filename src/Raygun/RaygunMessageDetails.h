//
//  RaygunMessageDetails.h
//  Raygun4iOS
//
//  Created by Mitchell Duncan on 11/09/17.
//  Copyright © 2017 Mindscape. All rights reserved.
//

#ifndef RaygunMessageDetails_h
#define RaygunMessageDetails_h

#import "RaygunClientMessage.h"
#import "RaygunEnvironmentMessage.h"
#import "RaygunErrorMessage.h"
#import "RaygunUserInformation.h"
#import "RaygunThread.h"
#import "RaygunBinaryImage.h"

@interface RaygunMessageDetails : NSObject

@property (nonatomic, readwrite, copy) NSString *groupingKey;
@property (nonatomic, readwrite, copy) NSString *machineName;
@property (nonatomic, readwrite, copy) NSString *version;
@property (nonatomic, readwrite, strong) RaygunClientMessage *client;
@property (nonatomic, readwrite, strong) RaygunEnvironmentMessage *environment;
@property (nonatomic, readwrite, strong) RaygunErrorMessage *error;
@property (nonatomic, readwrite, strong) RaygunUserInformation *user;
@property (nonatomic, readwrite, strong) NSArray *tags;
@property (nonatomic, readwrite, strong) NSDictionary *customData;
@property (nonatomic, strong) NSArray<RaygunThread *> *threads;
@property (nonatomic, strong) NSArray<RaygunBinaryImage *> *binaryImages;

/**
 Creates and returns a dictionary with the classes properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the classes properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunMessageDetails_h */

