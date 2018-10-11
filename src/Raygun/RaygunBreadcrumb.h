//
//  RaygunBreadcrumb.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 10/10/18.
//

#ifndef RaygunBreadcrumb_h
#define RaygunBreadcrumb_h

#import <Foundation/Foundation.h>
#import "RaygunDefines.h"

@class RaygunBreadcrumb;

typedef void(^RaygunBreadcrumbBlock)(RaygunBreadcrumb *breadcrumb);

@interface RaygunBreadcrumb : NSObject

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *category;
@property (nonatomic) enum  RaygunBreadcrumbLevel level;
@property (nonatomic) enum  RaygunBreadcrumbType type;
@property (nonatomic, copy) NSNumber *occurredOn;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *methodName;
@property (nonatomic, copy) NSNumber *lineNumber;
@property (nonatomic, strong) NSDictionary *customData;

+ (instancetype)breadcrumbWithBlock:(RaygunBreadcrumbBlock)block;
- (instancetype)initWithBlock:(RaygunBreadcrumbBlock)block NS_DESIGNATED_INITIALIZER;

- (NSDictionary *)convertToDictionary;

@end

#endif /* RaygunBreadcrumb_h */
