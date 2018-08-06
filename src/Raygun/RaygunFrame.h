//
//  RaygunFrame.h
//  raygun4apple
//
//  Created by raygundev on 8/2/18.
//

#ifndef RaygunFrame_h
#define RaygunFrame_h

#import <Foundation/Foundation.h>

@interface RaygunFrame : NSObject

@property(nonatomic, readwrite, copy) NSNumber *instructionAddress;

- (id)init;

/**
 Creates and returns a dictionary with the frame properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the frame properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunFrame_h */
