//
//  RaygunThread.m
//  raygun4apple
//
//  Created by raygundev on 8/2/18.
//

#import "RaygunThread.h"

@implementation RaygunThread

- (instancetype)init:(NSNumber *)threadIndex {
    self = [super init];
    if (self) {
        self.threadIndex = threadIndex;
    }
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"index":self.threadIndex,
                                                                                @"crashed":self.crashed?@YES:@NO,
                                                                                @"current":self.current?@YES:@NO
                                                                                }];
    
    if (self.name){
        dict[@"name"] = self.name;
    }
    if (self.threadIndex){
        dict[@"threadNumber"] = self.threadIndex;
    }
    if (self.crashed){
        dict[@"crashed"] = self.crashed?@YES:@NO;
    }
    
    NSMutableArray *frames = [NSMutableArray new];
    for (RaygunFrame *frame in self.frames) {
        NSDictionary *serialized = [frame convertToDictionary];
        if (serialized.allKeys.count > 0) {
            [frames addObject:serialized];
        }
    }
    dict[@"stackFrames"] = frames;
    
    return dict;
}

@end
