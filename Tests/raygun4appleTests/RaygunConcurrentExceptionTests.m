//
//  RaygunConcurrentExceptionTests.m
//  raygun4appleTests
//
//  Tests for GitHub issue #70:
//  When two exceptions are sent back-to-back, the second exception's
//  name/reason can be lost or mixed with the first exception's data.
//

#import <XCTest/XCTest.h>

@import raygun4apple;

@interface RaygunConcurrentExceptionTests : XCTestCase

@end

@implementation RaygunConcurrentExceptionTests

- (void)setUp {
    [super setUp];
}

/// Verifies that two exceptions sent back-to-back produce two distinct messages
/// with the correct exception names and reasons.
///
/// This test reproduces the bug reported in issue #70 where rapid successive calls
/// to sendException result in lost or mixed exception data due to:
/// 1. The shared KSCrash sink being overwritten by the second call
/// 2. deleteAllReports running after the first async completion, removing the second report
/// 3. Both async blocks racing to process the same set of reports
- (void)testBackToBackExceptionsRetainDistinctNames {
    // Set up the client with crash reporting
    RaygunClient *client = [RaygunClient sharedInstanceWithApiKey:@"test-api-key"];
    [client enableCrashReporting];

    // Capture all messages that pass through sendMessage:
    NSMutableArray<RaygunMessage *> *capturedMessages = [NSMutableArray array];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    // Use beforeSendMessage to intercept messages before they are sent via HTTP.
    // Return NO to prevent actual network calls, but still capture the message.
    client.beforeSendMessage = ^BOOL(RaygunMessage *message) {
        @synchronized (capturedMessages) {
            [capturedMessages addObject:message];
            // Signal once we've captured 2 messages (or on each to avoid deadlock)
            dispatch_semaphore_signal(semaphore);
        }
        return NO; // Prevent actual HTTP send
    };

    // Send two exceptions back-to-back with distinct names and reasons
    [client sendException:@"Exception_Title_1"
               withReason:@"Reason_1"
                 withTags:@[@"tag1"]
           withCustomData:@{@"key": @"value1"}];

    [client sendException:@"Exception_Title_2"
               withReason:@"Reason_2"
                 withTags:@[@"tag2"]
           withCustomData:@{@"key": @"value2"}];

    // Wait for both async report processing pipelines to deliver messages.
    // Each sendException triggers an async dispatch_async in RaygunCrashReportCustomSink.
    long result1 = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    long result2 = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));

    XCTAssertEqual(result1, 0, @"Timed out waiting for first message");
    XCTAssertEqual(result2, 0, @"Timed out waiting for second message");

    // Verify we received exactly 2 messages
    @synchronized (capturedMessages) {
        XCTAssertEqual(capturedMessages.count, 2,
                       @"Expected 2 messages but got %lu. One or both exceptions were lost.",
                       (unsigned long)capturedMessages.count);
    }

    // Extract exception class names from captured messages
    NSMutableSet<NSString *> *capturedNames = [NSMutableSet set];
    NSMutableSet<NSString *> *capturedReasons = [NSMutableSet set];

    @synchronized (capturedMessages) {
        for (RaygunMessage *msg in capturedMessages) {
            [capturedNames addObject:msg.details.error.className];
            [capturedReasons addObject:msg.details.error.message];
        }
    }

    // Verify both distinct exception names are present
    XCTAssertTrue([capturedNames containsObject:@"Exception_Title_1"],
                  @"Missing 'Exception_Title_1' in captured messages. Got: %@", capturedNames);
    XCTAssertTrue([capturedNames containsObject:@"Exception_Title_2"],
                  @"Missing 'Exception_Title_2' in captured messages. Got: %@", capturedNames);

    // Verify both distinct reasons are present
    XCTAssertTrue([capturedReasons containsObject:@"Reason_1"],
                  @"Missing 'Reason_1' in captured messages. Got: %@", capturedReasons);
    XCTAssertTrue([capturedReasons containsObject:@"Reason_2"],
                  @"Missing 'Reason_2' in captured messages. Got: %@", capturedReasons);

    // Verify each message has the correct name-reason pairing
    @synchronized (capturedMessages) {
        for (RaygunMessage *msg in capturedMessages) {
            NSString *name = msg.details.error.className;
            NSString *reason = msg.details.error.message;

            if ([name isEqualToString:@"Exception_Title_1"]) {
                XCTAssertEqualObjects(reason, @"Reason_1",
                                      @"Exception_Title_1 should have Reason_1 but got %@", reason);
            } else if ([name isEqualToString:@"Exception_Title_2"]) {
                XCTAssertEqualObjects(reason, @"Reason_2",
                                      @"Exception_Title_2 should have Reason_2 but got %@", reason);
            }
        }
    }

    // Verify tags were not mixed between the two calls
    @synchronized (capturedMessages) {
        for (RaygunMessage *msg in capturedMessages) {
            NSString *name = msg.details.error.className;
            NSArray *tags = msg.details.tags;

            if ([name isEqualToString:@"Exception_Title_1"]) {
                XCTAssertTrue([tags containsObject:@"tag1"],
                              @"Exception_Title_1 should have tag1 but got %@", tags);
                XCTAssertFalse([tags containsObject:@"tag2"],
                               @"Exception_Title_1 should not have tag2 but got %@", tags);
            } else if ([name isEqualToString:@"Exception_Title_2"]) {
                XCTAssertTrue([tags containsObject:@"tag2"],
                              @"Exception_Title_2 should have tag2 but got %@", tags);
                XCTAssertFalse([tags containsObject:@"tag1"],
                               @"Exception_Title_2 should not have tag1 but got %@", tags);
            }
        }
    }
}

@end
