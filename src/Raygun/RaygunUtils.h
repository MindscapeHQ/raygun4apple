//
//  RaygunUtils.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 10/10/18.
//

#ifndef RaygunUtils_h
#define RaygunUtils_h

#import <Foundation/Foundation.h>

@interface RaygunUtils : NSObject

+ (BOOL)isNullOrEmpty:(id _Nullable)thing;

+ (NSString *)currentDateTime;

+ (NSNumber *)timeSinceEpochInMilliseconds;

@end

#endif /* RaygunUtils_h */
