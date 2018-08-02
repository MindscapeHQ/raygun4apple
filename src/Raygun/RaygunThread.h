//
//  RaygunThread.h
//  raygun4apple
//
//  Created by raygundev on 8/2/18.
//

#ifndef RaygunThread_h
#define RaygunThread_h

#import <Foundation/Foundation.h>
#import "RaygunStacktrace.h"

@interface RaygunThread : NSObject

@property(nonatomic, readwrite, copy) NSNumber *threadIndex;
@property(nonatomic, readwrite, copy) NSString *name;
@property(nonatomic, strong) RaygunStacktrace *stacktrace;
@property(nonatomic, readwrite) BOOL crashed;
@property(nonatomic, readwrite) BOOL current;

/**
 * Initializes a RaygunThread with its index

 * @return RaygunThread
 */
- (id)init:(NSNumber *)threadIndex;

/**
 Creates and returns a dictionary with the thread properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the thread properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunThread_h */
