//
//  RaygunCrashReportCustomSink.m
//  TestiOSWithSrc
//
//  Created by Mitchell Duncan on 24/08/18.
//  Copyright © 2018 Raygun. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Raygun.h"
#import "RaygunMessage.h"
#import "RaygunCrashReportConverter.h"
#import "RaygunCrashReportCustomSink.h"
#import "KSCrash.h"

@interface RaygunCrashReportCustomSink()

@property (nonatomic, readwrite, retain) NSArray *tags;
@property (nonatomic, readwrite, retain) NSDictionary *customData;

@end

@implementation RaygunCrashReportCustomSink

-(id)initWithTags:(NSArray *)tags withCustomData:(NSDictionary *)customData {
    if ((self = [super init])) {
        self.tags = tags;
        self.customData = customData;
    }
    return self;
}

- (void) filterReports:(NSArray *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSMutableArray *sentReports = [NSMutableArray new];
        RaygunCrashReportConverter *converter = [[RaygunCrashReportConverter alloc] init];
        
        for (NSDictionary *report in reports) {
            if (nil != Raygun.sharedClient) {
                RaygunMessage *message = [converter convertReportToMessage:report];
                
                // Add tags
                if (self.tags && self.tags.count > 0) {
                    NSMutableArray *combinedTags = [NSMutableArray arrayWithArray:message.details.tags];
                    [combinedTags addObjectsFromArray:self.tags];
                    message.details.tags = combinedTags;
                }

                // Add custom data
                if (self.customData && self.customData.count > 0) {
                    NSMutableDictionary *combinedCustomData = [NSMutableDictionary dictionaryWithDictionary:message.details.customData];
                    [combinedCustomData addEntriesFromDictionary:self.customData];
                    message.details.customData = combinedCustomData;
                }
                
                [Raygun.sharedClient sendMessage:message];
                [sentReports addObject:report];
            }
        }
        if (onCompletion) {
            onCompletion(sentReports, TRUE, nil);
        }
    });
}

@end
