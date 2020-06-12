//
//  AppDelegate.m
//  iOS-ObjectiveC-CocoaPods
//
//  Created by Mitchell Duncan on 11/06/20.
//  Copyright © 2020 Raygun. All rights reserved.
//

#import "AppDelegate.h"
#import <raygun4apple/raygun4apple_iOS.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set the client logging level
    RaygunClient.logLevel = RaygunLoggingLevelVerbose;
    
    // Instantiate the client
    RaygunClient *raygunClient = [RaygunClient sharedInstanceWithApiKey:@"nGEXUcvTAUr7Kom9KsBy9w=="];
    
    // Configure the client
    raygunClient.tags = @[@"global_tag", @"CocoaPods"];
    raygunClient.customData = @{ @"globalMessage" : @"Hello, World!", @"globalMagicNumber" : @1 };
    
    // Modify or cancel messages by setting a handler for the beforeSendMessage event.
    raygunClient.beforeSendMessage = ^BOOL(RaygunMessage * _Nonnull message)
    {
        if ([message.details.machineName isEqualToString:@"LOCAL_MACBOOK"]) {
          return NO; // Cancel sending the report
        }
        
        return YES;
    };
    
    // Enable products
    [RaygunClient.sharedInstance enableCrashReporting];
    [RaygunClient.sharedInstance enableRealUserMonitoring];
    [RaygunClient.sharedInstance enableNetworkPerformanceMonitoring];
    
    // Send a test error report to Raygun.
    [RaygunClient.sharedInstance sendException:@"Raygun has been successfully integrated!"
                                    withReason:@"A test crash report from Raygun"
                                      withTags:@[@"Test"]
                                withCustomData:@{@"TestMessage":@"Hello World!"}];
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
