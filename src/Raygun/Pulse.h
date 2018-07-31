//
//  Pulse.h
//  Raygun4iOS
//
//  Created by Jason Fauchelle on 27/04/16.
//  Copyright © 2016 Raygun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RaygunUserInfo.h"

@interface Pulse : NSObject

- (id)initWithApiKey:(NSString *)apiKey;

- (void)attach;

- (void)attachWithNetworkLogging:(bool)networkLogging;

- (void)identifyWithUserInfo:(RaygunUserInfo *)userInfo;

- (void)ignoreViews:(NSArray *)viewNames;

- (void)ignoreURLs:(NSArray *)urls;

+ (void)sendPulseEvent:(NSString*)name withType:(NSString*)type withDuration:(NSNumber*)duration;

@end
