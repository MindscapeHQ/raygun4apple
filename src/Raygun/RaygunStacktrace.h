//
//  RaygunStacktrace.h
//  raygun4apple
//
//  Created by raygundev on 8/2/18.
//

#ifndef RaygunStacktrace_h
#define RaygunStacktrace_h

#import <Foundation/Foundation.h>
#import "RaygunFrame.h"

@interface RaygunStacktrace : NSObject

@property(nonatomic, strong) NSArray<RaygunFrame *> *frames;

/**
 * Initialize a RaygunStacktrace with frames
 
 * @return RaygunStacktrace
 */
- (id)init:(NSArray<RaygunFrame *> *)frames;

/**
 Creates and returns a dictionary with the stacktrace properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the stacktrace properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunStacktrace_h */
