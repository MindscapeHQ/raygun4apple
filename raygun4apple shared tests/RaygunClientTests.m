//
//  RaygunClientTests.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 9/01/19.
//

#import <XCTest/XCTest.h>

#import "RaygunClient.h"
#import "RaygunDefines.h"

@interface RaygunClientTests : XCTestCase

@end

@implementation RaygunClientTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSharedClient {
    RaygunClient *client = [RaygunClient sharedInstanceWithApiKey:@"api_key"];
    XCTAssertNotNil(client);
    XCTAssertNotNil(RaygunClient.sharedInstance);
}

- (void)testSharedAPIKey {
    RaygunClient *client = [[RaygunClient alloc] initWithApiKey:@"123456"];
    XCTAssertNotNil(client);
    XCTAssertNotNil(RaygunClient.apiKey);
    XCTAssertEqual(RaygunClient.apiKey, @"123456");
}

- (void)testEventTypeNames {
    XCTAssertEqual(RaygunEventTypeNames[RaygunEventTypeSessionStart], @"session_start");
    XCTAssertEqual(RaygunEventTypeNames[RaygunEventTypeSessionEnd], @"session_end");
    XCTAssertEqual(RaygunEventTypeNames[RaygunEventTypeTiming], @"mobile_event_timing");
}

- (void)testEventTimingTypeNames {
    XCTAssertEqual(RaygunEventTimingTypeShortNames[RaygunEventTimingTypeViewLoaded], @"p");
    XCTAssertEqual(RaygunEventTimingTypeShortNames[RaygunEventTimingTypeNetworkCall], @"n");
}

@end

