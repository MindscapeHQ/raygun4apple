//
//  RaygunRealUserMonitoring.h
//  Raygun4iOS
//
//  Created by Jason Fauchelle on 27/04/16.
//  Copyright © 2016 Raygun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RaygunUserInformation.h"

@interface RaygunRealUserMonitoring : NSObject

- (id)initWithApiKey:(NSString *)apiKey;

- (void)enable;

- (void)attachWithNetworkLogging:(bool)networkLogging;

- (void)identifyWithUserInformation:(RaygunUserInformation *)userInformation;

- (void)ignoreViews:(NSArray *)viewNames;

- (void)ignoreURLs:(NSArray *)urls;

+ (void)sendEvent:(NSString*)name withType:(NSString*)type withDuration:(NSNumber*)duration;

@end
