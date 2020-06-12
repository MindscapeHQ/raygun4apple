//
//  RaygunNetworkPerformanceMonitor.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 17/10/16.
//  Copyright © 2018 Raygun Limited. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "RaygunNetworkPerformanceMonitor.h"

#import <Foundation/NSURLSession.h>

#import "RaygunDefines.h"

#if RAYGUN_CAN_USE_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import <objc/runtime.h>
#import <objc/message.h>
#import <sys/utsname.h>

#import "RaygunRealUserMonitoring.h"
#import "RaygunLogger.h"
#import "RaygunUtils.h"

#pragma mark - NSURLSessionTask Swizzle Declarations -

static IMP _original_resume_imp;
static IMP _original_cancel_imp;

void _swizzle_resume(id, SEL);
void _swizzle_cancel(id, SEL);

#pragma mark - NSURLConnection Swizzle Declarations -
static IMP _original_sendAsynchronousRequest_imp;
static IMP _original_sendSynchronousRequest_imp;

void    _swizzle_sendAsynchronousRequest(id, SEL, NSURLRequest*, NSOperationQueue*, void (^)(NSURLResponse*, NSData*, NSError*));
NSData* _swizzle_sendSynchronousRequest(id, SEL, NSURLRequest*, NSURLResponse* _Nullable*, NSError* _Nullable*);

#pragma mark - NSURLSession Swizzle Declarations -

static char const * const kSessionTaskIdKey = "RaygunSessionTaskId";

static IMP _original_sessionWithConfiguration_imp;
static IMP _original_dataTaskWithRequestAsync_imp;
static IMP _original_downloadTaskWithRequestNoHandlerAsync_imp;
static IMP _original_downloadTaskWithRequestAsync_imp;
static IMP _original_uploadTaskWithRequestFromDataNoHandler_imp;
static IMP _original_uploadTaskWithRequestFromData_imp;
static IMP _original_uploadTaskWithRequestFromFileNoHandler_imp;
static IMP _original_uploadTaskWithRequestFromFile_imp;

void                      _swizzle_didCompleteWithError(id, SEL, NSURLSession*, NSURLSessionTask*, NSError*);
NSURLSession*             _swizzle_sessionWithConfiguration(id, SEL, NSURLSessionConfiguration*, id, NSOperationQueue*);
NSURLSessionDataTask*     _swizzle_dataTaskWithRequestAsync(id, SEL, NSURLRequest*, void (^)(NSData*, NSURLResponse*, NSError*));
NSURLSessionDownloadTask* _swizzle_downloadTaskWithRequestNoHandlerAsync(id, SEL, NSURLRequest*);
NSURLSessionDownloadTask* _swizzle_downloadTaskWithRequestAsync(id, SEL, NSURLRequest*, void (^)(NSURL*, NSURLResponse*, NSError*));
NSURLSessionUploadTask*   _swizzle_uploadTaskWithRequestFromDataNoHandler(id, SEL, NSURLRequest*, NSData*);
NSURLSessionUploadTask*   _swizzle_uploadTaskWithRequestFromData(id, SEL, NSURLRequest*, NSData*, void (^)(NSData*, NSURLResponse*, NSError*));
NSURLSessionUploadTask*   _swizzle_uploadTaskWithRequestFromFileNoHandler(id, SEL, NSURLRequest*, NSURL*);
NSURLSessionUploadTask*   _swizzle_uploadTaskWithRequestFromFile(id, SEL, NSURLRequest*, NSURL*, void (^)(NSData*, NSURLResponse*, NSError*));

#pragma mark - RaygunNetworkPerformanceMonitor -

@implementation RaygunNetworkPerformanceMonitor

static bool enabled;
static NSMutableDictionary* timers;
static NSMutableSet* ignoredUrls;
static RaygunSessionTaskDelegate* sessionDelegate;

- (instancetype)init {
    if ((self = [super init])) {
        timers          = [[NSMutableDictionary alloc] init];
        sessionDelegate = [[RaygunSessionTaskDelegate alloc] init];
        ignoredUrls     = [[NSMutableSet alloc] init];
        [ignoredUrls addObject:@"api.raygun.com"];
    }
    return self;
}

- (void)enable {
    enabled = true;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RaygunLogger logDebug:@"Enabling Network Performance Monitoring"];
        [RaygunNetworkPerformanceMonitor swizzleUrlSessionTaskMethods];
        [RaygunNetworkPerformanceMonitor swizzleUrlSessionMethods];
        [RaygunNetworkPerformanceMonitor swizzleUrlConnectionMethods];
        [RaygunNetworkPerformanceMonitor swizzleUrlSessionDelegateMethods];
    });
}

- (void)ignoreURLs:(NSArray *)urls {
    if (urls != nil && ignoredUrls != nil) {
        for (NSString* url in urls) {
            if (url != nil) {
                [ignoredUrls addObject:url];
            }
        }
    }
}

- (BOOL)shouldIgnoreURL:(NSString *)urlName {
    if ([RaygunUtils isNullOrEmpty:urlName]) {
        return YES;
    }
    
    for (NSString* ignoredUrl in ignoredUrls) {
        if ([ignoredUrl containsString:urlName] || [urlName containsString:ignoredUrl]) {
            return YES;
        }
    }
    
    return NO;
}

+ (bool)isEnabled {
    return enabled;
}

+ (void)swizzleUrlSessionTaskMethods {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wnonnull"
        // Building invalid task to capture class information
        NSURLSessionDataTask *dataTask = [[NSURLSession sessionWithConfiguration:nil] dataTaskWithURL:nil];
        #pragma clang diagnostic pop
        
        Class taskClass = dataTask.superclass;
        
        Method m1 = class_getInstanceMethod(taskClass, @selector(resume));
        _original_resume_imp = method_setImplementation(m1, (IMP)_swizzle_resume);
        
        Method m2 = class_getInstanceMethod(taskClass, @selector(cancel));
        _original_cancel_imp = method_setImplementation(m2, (IMP)_swizzle_cancel);
        
        [dataTask cancel];
    });
}

+ (void)swizzleUrlSessionMethods {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method m0 = class_getClassMethod([NSURLSession class], @selector(sessionWithConfiguration:delegate:delegateQueue:));
        _original_sessionWithConfiguration_imp = method_setImplementation(m0, (IMP)_swizzle_sessionWithConfiguration);
        
        Method m1 = class_getInstanceMethod([NSURLSession class], @selector(dataTaskWithRequest:completionHandler:));
        _original_dataTaskWithRequestAsync_imp = method_setImplementation(m1, (IMP)_swizzle_dataTaskWithRequestAsync);
        
        Method m2 = class_getInstanceMethod([NSURLSession class], @selector(downloadTaskWithRequest:));
        _original_downloadTaskWithRequestNoHandlerAsync_imp = method_setImplementation(m2, (IMP)_swizzle_downloadTaskWithRequestNoHandlerAsync);
        
        Method m3 = class_getInstanceMethod([NSURLSession class], @selector(downloadTaskWithRequest:completionHandler:));
        _original_downloadTaskWithRequestAsync_imp = method_setImplementation(m3, (IMP)_swizzle_downloadTaskWithRequestAsync);
        
        Method m4 = class_getInstanceMethod([NSURLSession class], @selector(uploadTaskWithRequest:fromData:));
        _original_uploadTaskWithRequestFromDataNoHandler_imp = method_setImplementation(m4, (IMP)_swizzle_uploadTaskWithRequestFromDataNoHandler);
        
        Method m5 = class_getInstanceMethod([NSURLSession class], @selector(uploadTaskWithRequest:fromData:completionHandler:));
        _original_uploadTaskWithRequestFromData_imp = method_setImplementation(m5, (IMP)_swizzle_uploadTaskWithRequestFromData);
        
        Method m6 = class_getInstanceMethod([NSURLSession class], @selector(uploadTaskWithRequest:fromFile:));
        _original_uploadTaskWithRequestFromFileNoHandler_imp = method_setImplementation(m6, (IMP)_swizzle_uploadTaskWithRequestFromFileNoHandler);
        
        Method m7 = class_getInstanceMethod([NSURLSession class], @selector(uploadTaskWithRequest:fromFile:completionHandler:));
        _original_uploadTaskWithRequestFromFile_imp = method_setImplementation(m7, (IMP)_swizzle_uploadTaskWithRequestFromFile);
    });
}

+ (void)swizzleUrlConnectionMethods {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method m1 = class_getClassMethod([NSURLConnection class], @selector(sendAsynchronousRequest:queue:completionHandler:));
        _original_sendAsynchronousRequest_imp = method_setImplementation(m1, (IMP)_swizzle_sendAsynchronousRequest);
        
        Method m2 = class_getClassMethod([NSURLConnection class], @selector(sendSynchronousRequest:returningResponse:error:));
        _original_sendSynchronousRequest_imp = method_setImplementation(m2, (IMP)_swizzle_sendSynchronousRequest);
    });
}

+ (void)swizzleUrlSessionDelegateMethods {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SEL delegateSelector = @selector(URLSession:task:didCompleteWithError:);
        
        Class *classes = NULL;
        int numClasses = objc_getClassList(NULL, 0);
        
        if (numClasses > 0) {
            classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
            
            for (NSInteger classIndex = 0; classIndex < numClasses; ++classIndex) {
                Class class = classes[classIndex];
                
                if (class == [RaygunSessionTaskDelegate class] || class == [RaygunNetworkPerformanceMonitor class]) {
                    continue;
                }
                
                unsigned int methodCount = 0;
                Method *methods = class_copyMethodList(class, &methodCount);
                BOOL matchingSelectorFound = NO;
                
                for (unsigned int methodIndex = 0; methodIndex < methodCount; methodIndex++) {
                    
                    if (method_getName(methods[methodIndex]) == delegateSelector) {
                        matchingSelectorFound = YES;
                        break;
                    }
                }
                
                free(methods);
                
                if (matchingSelectorFound) {
                    [self swizzleDidCompleteWithError:class];
                }
            }
            free(classes);
        }
    });
}

+ (void)networkRequestStarted:(NSURLSessionTask *)task {
    if (![RaygunNetworkPerformanceMonitor shouldIgnore:task.originalRequest]) {
        NSNumber* start = @(CACurrentMediaTime());
        NSString* taskId = objc_getAssociatedObject(task, kSessionTaskIdKey);
        if (taskId != nil) {
            timers[taskId] = start;
        }
    }
}

+ (void)networkRequestEnded:(NSURLRequest *)request withTaskId:(NSString *)taskId {
    if(request != nil && taskId != nil){
        NSNumber* start = timers[taskId];
        if (start != nil) {
            double interval = CACurrentMediaTime() - start.doubleValue;
            [RaygunNetworkPerformanceMonitor sendTimingEvent:request withDuration:interval * 1000];
        }
        [timers removeObjectForKey:taskId];
    }
}

+ (void)networkRequestCanceled:(NSString *)taskId {
    if (taskId != nil) {
        [timers removeObjectForKey:taskId];
    }
}

+ (void)sendTimingEvent:(NSURLRequest *)request withDuration:(double)milliseconds {
    if (![RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        NSString* urlString  = request.URL.relativeString;
        NSString* httpMethod = request.HTTPMethod;
        
        urlString = [RaygunNetworkPerformanceMonitor sanitiseURL:urlString];
        
        if (httpMethod != nil) {
            urlString = [NSString stringWithFormat:@"%@ %@", httpMethod, urlString];
        }
        
        [[RaygunRealUserMonitoring sharedInstance] sendTimingEvent:RaygunEventTimingTypeNetworkCall withName:urlString withDuration:[NSNumber numberWithInteger:milliseconds]];
    }
}

+ (bool)shouldIgnore:(NSURLRequest *)request {
    if (!enabled) {
        return true;
    }
    
    if (request == nil) {
        return true;
    }
    
    NSURL* url = request.URL;
    
    if (url == nil) {
        return true;
    }
    
    NSString* urlString = url.relativeString;
    
    if (urlString == nil) {
        return true;
    }
    
    for (NSString* ignoredUrl in ignoredUrls) {
        if ([ignoredUrl containsString:urlString] || [urlString containsString:ignoredUrl]) {
            return true;
        }
    }
    
    return false;
}

+ (NSString*)sanitiseURL:(NSString*)urlString {
    NSArray* splitURL = [urlString componentsSeparatedByString:@"?"];
    return splitURL[(0)];
}

+ (id)getSessionTaskDelegate {
    return sessionDelegate;
}

+ (void)swizzleDidCompleteWithError:(Class)delegateClass
{
    SEL selector = @selector(URLSession:task:didCompleteWithError:);
    SEL swizzleSelector = NSSelectorFromString([NSString stringWithFormat:@"_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
    
    Protocol* protocol = @protocol(NSURLSessionTaskDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionTaskDidCompleteWithErrorBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error);
    
    NSURLSessionTaskDidCompleteWithErrorBlock networkLoggingBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        [RaygunNetworkPerformanceMonitor URLSession:session task:task didCompleteWithError:error];
    };
    
    NSURLSessionTaskDidCompleteWithErrorBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        [self logWithoutDuplicationForObject:session
                                    selector:selector
                         networkLoggingBlock:^{ networkLoggingBlock(slf, session, task, error); }
                 originalImplementationBlock:^{ ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzleSelector, session, task, error); }];
    };
    
    IMP implementation = imp_implementationWithBlock((id)networkLoggingBlock);
    
    if ([delegateClass instancesRespondToSelector:selector]) {
        implementation = imp_implementationWithBlock((id)implementationBlock);
    }
    
    Method originalMethod = class_getInstanceMethod(delegateClass, selector);
    
    if (originalMethod) {
        class_addMethod(delegateClass, swizzleSelector, implementation, methodDescription.types);
        
        Method swizzleMethod = class_getInstanceMethod(delegateClass, swizzleSelector);
        
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
    else {
        class_addMethod(delegateClass, selector, implementation, methodDescription.types);
    }
}

+ (void)logWithoutDuplicationForObject:(NSObject *)object
                              selector:(SEL)selector
                   networkLoggingBlock:(void (^)(void))networkLoggingBlock
           originalImplementationBlock:(void (^)(void))originalImplementationBlock
{
    // If we don't have an object to detect nested calls on, just run the original implmentation and bail.
    // This case can happen if someone besides the URL loading system calls the delegate methods directly.
    if (!object) {
        originalImplementationBlock();
        return;
    }
    
    const void *key = selector;
    
    // Don't run the logging block if we're inside a nested call
    if (!objc_getAssociatedObject(object, key)) {
        networkLoggingBlock();
    }
    
    // Mark that we're calling through to the original so we can detect nested calls
    objc_setAssociatedObject(object, key, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    originalImplementationBlock();
    
    objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    NSString* taskId = objc_getAssociatedObject(task, kSessionTaskIdKey);
    
    if (error == nil) {
        [RaygunNetworkPerformanceMonitor networkRequestEnded:task.originalRequest withTaskId:taskId];
    }
    else {
        [RaygunNetworkPerformanceMonitor networkRequestCanceled:taskId];
    }
}

+ (void)checkForDelegateImp:(Class)delegateClass {
    SEL selector = @selector(URLSession:task:didCompleteWithError:);
    
    // Walk up the hierarchy looking for imp
    BOOL foundImp = NO;
    Class cls = delegateClass;
    
    while (cls != nil)
    {
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(cls, &methodCount);
        
        for (unsigned int methodIndex = 0; methodIndex < methodCount; methodIndex++) {
            if (method_getName(methods[methodIndex]) == selector) {
                foundImp = YES;
                break;
            }
        }
        
        free(methods);
        
        if (foundImp) {
            cls = nil;
        }
        else {
            cls = [cls superclass];
        }
    }
    
    // if not found add it
    if (!foundImp) {
        [self swizzleDidCompleteWithError:delegateClass];
    }
}

@end

#pragma mark - NSURLSession Swizzle Imp -

NSURLSession* _swizzle_sessionWithConfiguration(id slf, SEL _cmd, NSURLSessionConfiguration* config, id delegate, NSOperationQueue* queue) {
    [RaygunNetworkPerformanceMonitor checkForDelegateImp:[delegate class]];
    
    if (delegate != nil) {
        return ((NSURLSession*(*)(id, SEL, NSURLSessionConfiguration*, id, NSOperationQueue*))_original_sessionWithConfiguration_imp)(slf, _cmd, config, delegate, queue);
    }
    else {
        return ((NSURLSession*(*)(id, SEL, NSURLSessionConfiguration*, id, NSOperationQueue*))_original_sessionWithConfiguration_imp)(slf, _cmd, config, [RaygunNetworkPerformanceMonitor getSessionTaskDelegate], queue);
    }
}

#pragma mark - NSURLSessionTask Swizzle Imp -

void _swizzle_resume(id slf, SEL _cmd) {
    [RaygunNetworkPerformanceMonitor networkRequestStarted:slf];
    ((void(*)(id, SEL))_original_resume_imp)(slf, _cmd);
}

void _swizzle_cancel(id slf, SEL _cmd) {
    NSString* taskId = objc_getAssociatedObject(slf, kSessionTaskIdKey);
    [RaygunNetworkPerformanceMonitor networkRequestCanceled:taskId];
    objc_setAssociatedObject(slf, kSessionTaskIdKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    ((void(*)(id, SEL))_original_cancel_imp)(slf, _cmd);
}

#pragma mark - NSURLConnection Swizzle Imp -

void _swizzle_sendAsynchronousRequest(id slf, SEL _cmd, NSURLRequest* request, NSOperationQueue* queue, void (^handler)(NSURLResponse*, NSData*, NSError*)) {
    if ([RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        ((void(*)(id, SEL, NSURLRequest*, NSOperationQueue*, void (^)(NSURLResponse*, NSData*, NSError*)))_original_sendAsynchronousRequest_imp)(slf, _cmd, request, queue, handler);
    }
    else {
        double start = CACurrentMediaTime();
        
        ((void(*)(id, SEL, NSURLRequest*, NSOperationQueue*, void (^)(NSURLResponse*, NSData*, NSError*)))
         _original_sendAsynchronousRequest_imp)(slf, _cmd, request, queue, ^(NSURLResponse *response, NSData *data, NSError *error)
                                                {
                                                    double interval = CACurrentMediaTime() - start;
                                                    
                                                    if (handler != nil) {
                                                        handler(response, data, error);
                                                    }
                                                    
                                                    [RaygunNetworkPerformanceMonitor sendTimingEvent:request withDuration:interval * 1000];
                                                });
    }
}

NSData* _swizzle_sendSynchronousRequest(id slf, SEL _cmd, NSURLRequest* request, NSURLResponse* _Nullable* response, NSError* _Nullable* error) {
    if ([RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        return ((NSData*(*)(id, SEL, NSURLRequest*, NSURLResponse* _Nullable*, NSError* _Nullable*))_original_sendSynchronousRequest_imp)(slf, _cmd, request, response, error);
    }
    
    double start = CACurrentMediaTime();
    NSData* result = ((NSData*(*)(id, SEL, NSURLRequest*, NSURLResponse* _Nullable*, NSError* _Nullable*))_original_sendSynchronousRequest_imp)(slf, _cmd, request, response, error);
    double interval = CACurrentMediaTime() - start;
    
    [RaygunNetworkPerformanceMonitor sendTimingEvent:request withDuration:interval * 1000];
    
    return result;
}

#pragma mark - NSURLSession Data Swizzle Imp -

NSURLSessionDataTask* _swizzle_dataTaskWithRequestAsync(id slf, SEL _cmd, NSURLRequest* request, void (^handler)(NSData*, NSURLResponse*, NSError*)) {
    if ([RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        return ((NSURLSessionDataTask*(*)(id, SEL, NSURLRequest*, void (^)(NSData*, NSURLResponse*, NSError*)))_original_dataTaskWithRequestAsync_imp)(slf, _cmd, request, handler);
    }
    
    NSString* taskId = [NSUUID UUID].UUIDString;
    
    if (handler != nil) {
        NSURLSessionDataTask* task = ((NSURLSessionDataTask*(*)(id, SEL, NSURLRequest*, void (^)(NSData*, NSURLResponse*, NSError*)))
                                      _original_dataTaskWithRequestAsync_imp)(slf, _cmd, request, ^(NSData* data, NSURLResponse* response, NSError* error)
                                                                              {
                                                                                  if (error == nil) {
                                                                                      [RaygunNetworkPerformanceMonitor networkRequestEnded:request withTaskId:taskId];
                                                                                  }
                                                                                  else {
                                                                                      [RaygunNetworkPerformanceMonitor networkRequestCanceled:taskId];
                                                                                  }
                                                                                  
                                                                                  if (handler != nil) {
                                                                                      handler(data, response, error);
                                                                                  }
                                                                              });
        
        objc_setAssociatedObject(task, kSessionTaskIdKey, taskId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return task;
    }
    else {
        NSURLSessionDataTask* task = ((NSURLSessionDataTask*(*)(id, SEL, NSURLRequest*, void (^)(NSData*, NSURLResponse*, NSError*)))_original_dataTaskWithRequestAsync_imp)(slf, _cmd, request, handler);
        
        objc_setAssociatedObject(task, kSessionTaskIdKey, taskId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return task;
    }
}

#pragma mark - NSURLSession Download Swizzle Imp -

NSURLSessionDownloadTask* _swizzle_downloadTaskWithRequestNoHandlerAsync(id slf, SEL _cmd, NSURLRequest* request) {
    
    if ([RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        return ((NSURLSessionDownloadTask*(*)(id, SEL, NSURLRequest*))_original_downloadTaskWithRequestNoHandlerAsync_imp)(slf, _cmd, request);
    }
    
    NSURLSessionDownloadTask* task = ((NSURLSessionDownloadTask*(*)(id, SEL, NSURLRequest*))_original_downloadTaskWithRequestNoHandlerAsync_imp)(slf, _cmd, request);
    
    NSString* taskId = [NSUUID UUID].UUIDString;
    
    objc_setAssociatedObject(task, kSessionTaskIdKey, taskId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return task;
}

NSURLSessionDownloadTask* _swizzle_downloadTaskWithRequestAsync(id slf, SEL _cmd, NSURLRequest* request, void (^handler)(NSURL*, NSURLResponse*, NSError*)) {
    if ([RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        return ((NSURLSessionDownloadTask*(*)(id, SEL, NSURLRequest*, void (^)(NSURL*, NSURLResponse*, NSError*)))_original_downloadTaskWithRequestAsync_imp)(slf, _cmd, request, handler);
    }
    
    NSString* taskId = [NSUUID UUID].UUIDString;
    
    if (handler != nil) {
        NSURLSessionDownloadTask* task = ((NSURLSessionDownloadTask*(*)(id, SEL, NSURLRequest*, void (^)(NSURL*, NSURLResponse*, NSError*)))
                                          _original_downloadTaskWithRequestAsync_imp)(slf, _cmd, request, ^(NSURL* location, NSURLResponse* response, NSError* error)
                                                                                      {
                                                                                          if (error == nil) {
                                                                                              [RaygunNetworkPerformanceMonitor networkRequestEnded:request withTaskId:taskId];
                                                                                          }
                                                                                          else {
                                                                                              [RaygunNetworkPerformanceMonitor networkRequestCanceled:taskId];
                                                                                          }
                                                                                          
                                                                                          if (handler != nil) {
                                                                                              handler(location, response, error);
                                                                                          }
                                                                                      });
        
        objc_setAssociatedObject(task, kSessionTaskIdKey, taskId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return task;
    }
    else {
        NSURLSessionDownloadTask* task = ((NSURLSessionDownloadTask*(*)(id, SEL, NSURLRequest*, void (^)(NSURL*, NSURLResponse*, NSError*)))_original_downloadTaskWithRequestAsync_imp)(slf, _cmd, request, handler);
        
        objc_setAssociatedObject(task, kSessionTaskIdKey, taskId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return task;
    }
}

#pragma mark - NSURLSession Upload Swizzle Imp -

NSURLSessionUploadTask* _swizzle_uploadTaskWithRequestFromDataNoHandler(id slf, SEL _cmd, NSURLRequest* request, NSData* bodyData) {
    if ([RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        return ((NSURLSessionUploadTask*(*)(id, SEL, NSURLRequest*, NSData*))_original_uploadTaskWithRequestFromDataNoHandler_imp)(slf, _cmd, request, bodyData);
    }
    
    NSString* taskId = [NSUUID UUID].UUIDString;
    
    NSURLSessionUploadTask* task = ((NSURLSessionUploadTask*(*)(id, SEL, NSURLRequest*, NSData*))_original_uploadTaskWithRequestFromDataNoHandler_imp)(slf, _cmd, request, bodyData);
    
    objc_setAssociatedObject(task, kSessionTaskIdKey, taskId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return task;
}

NSURLSessionUploadTask* _swizzle_uploadTaskWithRequestFromData(id slf, SEL _cmd, NSURLRequest* request, NSData* bodyData, void (^handler)(NSData*, NSURLResponse*, NSError*)) {
    if ([RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        return ((NSURLSessionUploadTask*(*)(id, SEL, NSURLRequest*, NSData*, void (^)(NSData*, NSURLResponse*, NSError*)))_original_uploadTaskWithRequestFromData_imp)(slf, _cmd, request, bodyData, handler);
    }
    
    NSString* taskId = [NSUUID UUID].UUIDString;
    
    NSURLSessionUploadTask* task = ((NSURLSessionUploadTask*(*)(id, SEL, NSURLRequest*, NSData*, void (^)(NSData*, NSURLResponse*, NSError*)))
                                    _original_uploadTaskWithRequestFromData_imp)(slf, _cmd, request, bodyData, ^(NSData* data, NSURLResponse* response, NSError* error)
                                                                                 {
                                                                                     if (error == nil) {
                                                                                         [RaygunNetworkPerformanceMonitor networkRequestEnded:request withTaskId:taskId];
                                                                                     }
                                                                                     else {
                                                                                         [RaygunNetworkPerformanceMonitor networkRequestCanceled:taskId];
                                                                                     }
                                                                                     
                                                                                     if (handler != nil) {
                                                                                         handler(data, response, error);
                                                                                     }
                                                                                 });
    
    objc_setAssociatedObject(task, kSessionTaskIdKey, taskId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return task;
}

NSURLSessionUploadTask* _swizzle_uploadTaskWithRequestFromFileNoHandler(id slf, SEL _cmd, NSURLRequest* request, NSURL* fileURL) {
    if ([RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        return ((NSURLSessionUploadTask*(*)(id, SEL, NSURLRequest*, NSURL*))_original_uploadTaskWithRequestFromFileNoHandler_imp)(slf, _cmd, request, fileURL);
    }
    
    NSString* taskId = [NSUUID UUID].UUIDString;
    
    NSURLSessionUploadTask* task = ((NSURLSessionUploadTask*(*)(id, SEL, NSURLRequest*, NSURL*))_original_uploadTaskWithRequestFromFileNoHandler_imp)(slf, _cmd, request, fileURL);
    
    objc_setAssociatedObject(task, kSessionTaskIdKey, taskId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return task;
}

NSURLSessionUploadTask* _swizzle_uploadTaskWithRequestFromFile(id slf, SEL _cmd, NSURLRequest* request, NSURL* fileURL, void (^handler)(NSData*, NSURLResponse*, NSError*)) {
    if ([RaygunNetworkPerformanceMonitor shouldIgnore:request]) {
        return ((NSURLSessionUploadTask*(*)(id, SEL, NSURLRequest*, NSURL*, void (^)(NSData*, NSURLResponse*, NSError*)))_original_uploadTaskWithRequestFromFile_imp)(slf, _cmd, request, fileURL, handler);
    }
    
    NSString* taskId = [NSUUID UUID].UUIDString;
    
    NSURLSessionUploadTask* task = ((NSURLSessionUploadTask*(*)(id, SEL, NSURLRequest*, NSURL*, void (^)(NSData*, NSURLResponse*, NSError*)))
                                    _original_uploadTaskWithRequestFromFile_imp)(slf, _cmd, request, fileURL, ^(NSData* data, NSURLResponse* response, NSError* error)
                                                                                 {
                                                                                     if (error == nil) {
                                                                                         [RaygunNetworkPerformanceMonitor networkRequestEnded:request withTaskId:taskId];
                                                                                     }
                                                                                     else {
                                                                                         [RaygunNetworkPerformanceMonitor networkRequestCanceled:taskId];
                                                                                     }
                                                                                     
                                                                                     if (handler != nil) {
                                                                                         handler(data, response, error);
                                                                                     }
                                                                                 });
    
    objc_setAssociatedObject(task, kSessionTaskIdKey, taskId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return task;
}

#pragma mark - RaygunSessionTaskDelegate -

@interface RaygunSessionTaskDelegate () <NSURLSessionTaskDelegate>

@end

@implementation RaygunSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    NSString* taskId = objc_getAssociatedObject(task, kSessionTaskIdKey);
    
    if (error == nil) {
        [RaygunNetworkPerformanceMonitor networkRequestEnded:task.originalRequest withTaskId:taskId];
    }
    else {
        [RaygunNetworkPerformanceMonitor networkRequestCanceled:taskId];
    }
}

@end
