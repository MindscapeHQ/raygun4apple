//
//  RaygunBinaryImage.h
//  raygun4apple
//
//  Created by raygundev on 8/3/18.
//

#ifndef RaygunBinaryImage_h
#define RaygunBinaryImage_h

#import <Foundation/Foundation.h>

@interface RaygunBinaryImage : NSObject

@property(nonatomic, readwrite, copy) NSNumber *cpuType;
@property(nonatomic, readwrite, copy) NSNumber *cpuSubtype;
@property(nonatomic, readwrite, copy) NSNumber *imageAddress;
@property(nonatomic, readwrite, copy) NSNumber *imageSize;
@property(nonatomic, readwrite, copy) NSString *name;
@property(nonatomic, readwrite, copy) NSString *uuid;

/**
 * Initializes a RaygunBinaryImage
 
 * @return RaygunBinaryImage
 */
- (id)initWithUuId:(NSString *)uuid
          withName:(NSString *)name
       withCpuType:(NSNumber *)cpuType
    withCpuSubType:(NSNumber *)cpuSubType
  withImageAddress:(NSNumber *)imageAddress
     withImageSize:(NSNumber *)imageSize;

/**
 Creates and returns a dictionary with the binary image properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the binary image properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunBinaryImage_h */
