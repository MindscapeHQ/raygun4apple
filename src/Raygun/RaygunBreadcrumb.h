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

/**
 The message you want to record for this breadcrumb
 */
@property (nonatomic, copy) NSString *message;

/**
 Any value to categorize your messages
 */
@property (nonatomic, copy) NSString *category;

/**
 The display level of the message (valid values are Debug, Info, Warning, Error)
 */
@property (nonatomic) enum  RaygunBreadcrumbLevel level;

/**
 The type of message (valid values are manual only currently)
 */
@property (nonatomic) enum  RaygunBreadcrumbType type;

/**
 Milliseconds since the Unix Epoch (required)
 */
@property (nonatomic, copy) NSNumber *occurredOn;

/**
 If relevant, a class name from where the breadcrumb was recorded
 */
@property (nonatomic, copy) NSString *className;

/**
 If relevant, a method name from where the breadcrumb was recorded
 */
@property (nonatomic, copy) NSString *methodName;

/**
 If relevant, a line number from where the breadcrumb was recorded
 */
@property (nonatomic, copy) NSNumber *lineNumber;

/**
 Any custom data you want to record about application state when the breadcrumb was recorded
 */
@property (nonatomic, strong) NSDictionary *customData;

+ (instancetype)breadcrumbWithBlock:(RaygunBreadcrumbBlock)block;

- (instancetype)initWithBlock:(RaygunBreadcrumbBlock)block NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)breadcrumbWithInformation:(NSDictionary *)information;

+ (BOOL)validate:(RaygunBreadcrumb *)breadcrumb withError:(NSError **)error;

- (NSDictionary *)convertToDictionary;

@end

#endif /* RaygunBreadcrumb_h */
