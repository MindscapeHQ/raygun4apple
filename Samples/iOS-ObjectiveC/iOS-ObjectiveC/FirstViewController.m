//
//  FirstViewController.m
//  iOS-ObjectiveC
//
//  Created by Mitchell Duncan on 11/06/20.
//  Copyright © 2020 Raygun. All rights reserved.
//

#import "FirstViewController.h"
#import <raygun4apple/raygun4apple_iOS.h>

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Add a button to trigger the concurrent breadcrumb test
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [testButton setTitle:@"Test Concurrent Breadcrumbs" forState:UIControlStateNormal];
    testButton.frame = CGRectMake(50, 100, 300, 50);
    [testButton addTarget:self action:@selector(testConcurrentBreadcrumbs) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:testButton];
}

- (void)testConcurrentBreadcrumbs {
    // This test reproduces the "Collection was mutated while being enumerated" crash
    // that occurred when multiple threads accessed _mutableBreadcrumbs concurrently.
    // One thread would be iterating in updateCrashReportUserInformation while another
    // was adding/removing breadcrumbs.
    NSLog(@"Starting concurrent breadcrumb test...");

    // Create multiple concurrent queues to simulate real-world concurrent access
    dispatch_queue_t queue1 = dispatch_queue_create("com.raygun.test.queue1", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue2 = dispatch_queue_create("com.raygun.test.queue2", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue3 = dispatch_queue_create("com.raygun.test.queue3", DISPATCH_QUEUE_CONCURRENT);

    // Use a group to track when all operations complete
    dispatch_group_t group = dispatch_group_create();

    // Spawn multiple threads that all record breadcrumbs concurrently
    for (int i = 0; i < 100; i++) {
        dispatch_group_async(group, queue1, ^{
            [RaygunClient.sharedInstance recordBreadcrumbWithMessage:[NSString stringWithFormat:@"Queue1 Breadcrumb %d", i]
                withCategory:@"test"
                withLevel:RaygunBreadcrumbLevelInfo
                withCustomData:nil];
        });

        dispatch_group_async(group, queue2, ^{
            [RaygunClient.sharedInstance recordBreadcrumbWithMessage:[NSString stringWithFormat:@"Queue2 Breadcrumb %d", i]
                withCategory:@"test"
                withLevel:RaygunBreadcrumbLevelInfo
                withCustomData:nil];
        });

        dispatch_group_async(group, queue3, ^{
            [RaygunClient.sharedInstance recordBreadcrumbWithMessage:[NSString stringWithFormat:@"Queue3 Breadcrumb %d", i]
                withCategory:@"test"
                withLevel:RaygunBreadcrumbLevelInfo
                withCustomData:nil];
        });

        // Also clear breadcrumbs occasionally to increase contention
        if (i % 20 == 0) {
            dispatch_group_async(group, queue1, ^{
                [RaygunClient.sharedInstance clearBreadcrumbs];
            });
        }
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"Concurrent breadcrumb test completed - no crash means the fix is working!");

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Concurrent Breadcrumbs"
            message:@"Test completed successfully."
            preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

@end
