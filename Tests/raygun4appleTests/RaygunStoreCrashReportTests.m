//
//  RaygunStoreCrashReportTests.m
//  raygun4appleTests
//
//  Tests for the synchronous storeCrashReport: method on RaygunClient.
//

#import <XCTest/XCTest.h>

@import raygun4apple;

@interface RaygunStoreCrashReportTests : XCTestCase

@property (nonatomic, strong) RaygunClient *client;

@end

@implementation RaygunStoreCrashReportTests

- (void)setUp {
    [super setUp];
    self.client = [RaygunClient sharedInstanceWithApiKey:@"test-api-key"];
}

/// Helper to build a minimal RaygunMessage suitable for storing.
- (RaygunMessage *)buildTestMessage {
    RaygunErrorMessage *error = [[RaygunErrorMessage alloc] init:@"TestException"
                                                     withMessage:@"Something went wrong"
                                                  withSignalName:nil
                                                  withSignalCode:nil
                                                  withStackTrace:@[]];

    RaygunMessageDetails *details = [[RaygunMessageDetails alloc] init];
    details.error = error;
    details.version = @"1.0.0";
    details.client = [[RaygunClientMessage alloc] initWithName:@"test" withVersion:@"1.0" withUrl:@"https://test"];

    return [[RaygunMessage alloc] initWithTimestamp:@"2026-01-01T00:00:00Z" withDetails:details];
}

/// storeCrashReport should synchronously write the report to disk and return YES.
- (void)testStoreCrashReport_validMessage_writtenToDisk {
    self.client.beforeSendMessage = nil;

    // Count crash report files before
    NSString *crashesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
                             stringByAppendingPathComponent:@"com.raygun/crashes"];
    NSArray *filesBefore = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:crashesPath error:nil];
    NSUInteger countBefore = filesBefore ? filesBefore.count : 0;

    BOOL result = [self.client storeCrashReport:[self buildTestMessage]];

    XCTAssertTrue(result, @"storeCrashReport should return YES for a valid message");

    // Verify the file was written synchronously — no need to wait
    NSArray *filesAfter = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:crashesPath error:nil];
    XCTAssertEqual(filesAfter.count, countBefore + 1,
                   @"storeCrashReport should write exactly one new file to the crashes directory");

    // Clean up: remove the file we just created
    NSMutableSet *beforeSet = [NSMutableSet setWithArray:filesBefore ?: @[]];
    for (NSString *file in filesAfter) {
        if (![beforeSet containsObject:file]) {
            [[NSFileManager defaultManager] removeItemAtPath:[crashesPath stringByAppendingPathComponent:file] error:nil];
        }
    }
}

/// storeCrashReport should return NO when passed nil.
- (void)testStoreCrashReport_nilMessage_returnsNO {
    BOOL result = [self.client storeCrashReport:nil];

    XCTAssertFalse(result, @"storeCrashReport should return NO for a nil message");
}

/// storeCrashReport should return NO when beforeSendMessage discards the message.
- (void)testStoreCrashReport_beforeSendMessageReturnsNO_returnsNO {
    self.client.beforeSendMessage = ^BOOL(RaygunMessage *message) {
        return NO;
    };

    BOOL result = [self.client storeCrashReport:[self buildTestMessage]];

    XCTAssertFalse(result, @"storeCrashReport should return NO when beforeSendMessage discards the message");

    self.client.beforeSendMessage = nil;
}

/// storeCrashReport should pass the message through beforeSendMessage.
- (void)testStoreCrashReport_beforeSendMessageReceivesMessage {
    __block RaygunMessage *capturedMessage = nil;

    self.client.beforeSendMessage = ^BOOL(RaygunMessage *message) {
        capturedMessage = message;
        return NO; // prevent actual file write
    };

    RaygunMessage *testMessage = [self buildTestMessage];
    [self.client storeCrashReport:testMessage];

    XCTAssertNotNil(capturedMessage, @"beforeSendMessage should have been called");
    XCTAssertEqualObjects(capturedMessage.details.error.className, @"TestException",
                          @"beforeSendMessage should receive the original message");

    self.client.beforeSendMessage = nil;
}

/// storeCrashReport should apply the groupingKeyProvider before storing.
- (void)testStoreCrashReport_groupingKeyProviderApplied {
    __block NSString *appliedGroupingKey = nil;

    self.client.groupingKeyProvider = ^NSString *(RaygunMessageDetails *details) {
        return @"custom-group-key";
    };

    // Use beforeSendMessage to capture the message after grouping key is applied
    self.client.beforeSendMessage = ^BOOL(RaygunMessage *message) {
        appliedGroupingKey = message.details.groupingKey;
        return NO;
    };

    [self.client storeCrashReport:[self buildTestMessage]];

    XCTAssertEqualObjects(appliedGroupingKey, @"custom-group-key",
                          @"groupingKeyProvider should set the grouping key on the message");

    self.client.groupingKeyProvider = nil;
    self.client.beforeSendMessage = nil;
}

@end
