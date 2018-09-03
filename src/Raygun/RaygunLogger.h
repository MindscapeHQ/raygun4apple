//
//  RaygunLogger.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 31/08/18.
//

#ifndef RaygunLogger_h
#define RaygunLogger_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RaygunLogger : NSObject

+ (void)logError:(NSString *)message;

+ (void)logWarning:(NSString *)message;

+ (void)logDebug:(NSString *)message;

@end

NS_ASSUME_NONNULL_END

#endif /* RaygunLogger_h */
