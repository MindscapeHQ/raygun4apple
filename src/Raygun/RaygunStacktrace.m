//
//  RaygunStacktrace.m
//  raygun4apple
//
//  Created by raygundev on 8/2/18.
//

#import "RaygunStacktrace.h"
#import "RaygunFrame.h"

@implementation RaygunStacktrace

- (id)init:(NSArray<RaygunFrame *> *)frames {
    self = [super init];
    if (self) {
        self.frames = frames;
    }
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    NSMutableArray *frames = [NSMutableArray new];
    for (RaygunFrame *frame in self.frames) {
        NSDictionary *serialized = [frame convertToDictionary];
        if (serialized.allKeys.count > 0) {
            [frames addObject:serialized];
        }
    }
    dict[@"frame"] = frames;
    
    return dict;
}

@end
