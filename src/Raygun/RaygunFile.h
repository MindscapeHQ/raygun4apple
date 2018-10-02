//
//  RaygunFile.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 25/09/18.
//

#ifndef RaygunFile_h
#define RaygunFile_h

#import <Foundation/Foundation.h>

@interface RaygunFile : NSObject

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSData *data;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path withData:(NSData *)data NS_DESIGNATED_INITIALIZER;

@end

#endif /* RaygunFile_h */
