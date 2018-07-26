//
//  RaygunClient.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 18/07/18.
//

#ifndef RaygunClient_h
#define RaygunClient_h

#import <Foundation/Foundation.h>

@interface RaygunClient : NSObject

@property (nonatomic, readonly, copy) NSString *apiKey;

- (id)initWithApiKey:(NSString *)apiKey;

- (void)sendException:(NSException *)exception;

@end

#endif /* RaygunClient_h */
