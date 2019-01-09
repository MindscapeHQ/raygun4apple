//
//  RaygunBreadcrumbsTests.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 9/01/19.
//

#import <XCTest/XCTest.h>

#import "RaygunClient.h"
#import "RaygunBreadcrumb.h"

@interface RaygunBreadcrumbsTests : XCTestCase

@end

@implementation RaygunBreadcrumbsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)assertBreadcrumbCount:(RaygunClient*)client withCount:(NSUInteger)count {
    XCTAssertNotNil(client.breadcrumbs);
    XCTAssertEqual([client.breadcrumbs count], count);
}

- (void)testAddingBreadcrumbByInstance {
    RaygunClient *client = [[RaygunClient alloc] initWithApiKey:@"api_key"];
    
    // Started with no breadcrumbs
    [self assertBreadcrumbCount:client withCount:0];
    
    RaygunBreadcrumb *breadcrumb = [RaygunBreadcrumb breadcrumbWithBlock:^(RaygunBreadcrumb *crumb) {
        crumb.message    = @"block test message";
        crumb.category   = @"block test category";
        crumb.level      = RaygunBreadcrumbLevelError;
        crumb.className  = @"test className";
        crumb.methodName = @"test methodName";
        crumb.lineNumber = @123;
        crumb.customData = @{ @"block number": @123, @"block text": @"hello" };
    }];
    
    [client recordBreadcrumb:breadcrumb];
    
    [self assertBreadcrumbCount:client withCount:1];
}

- (void)testAddingBreadcrumbByDetails {
    RaygunClient *client = [[RaygunClient alloc] initWithApiKey:@"api_key"];
    
    // Started with no breadcrumbs
    [self assertBreadcrumbCount:client withCount:0];
    
    // Added one breadcrumb
    [client recordBreadcrumbWithMessage:@"test message"
                           withCategory:@"test category"
                              withLevel:RaygunBreadcrumbLevelInfo
                         withCustomData:nil];
    
    [self assertBreadcrumbCount:client withCount:1];
}

- (void)testClearingBreadcrumbs {
    RaygunClient *client = [[RaygunClient alloc] initWithApiKey:@"api_key"];
    
    // Started with no breadcrumbs
    [self assertBreadcrumbCount:client withCount:0];
    
    // Added one breadcrumb
    [client recordBreadcrumbWithMessage:@"test message"
                           withCategory:@"test category"
                              withLevel:RaygunBreadcrumbLevelInfo
                         withCustomData:nil];
    
    [self assertBreadcrumbCount:client withCount:1];
    
    // We cleared all breadcrumbs
    [client clearBreadcrumbs];
    
    [self assertBreadcrumbCount:client withCount:0];
}

@end
