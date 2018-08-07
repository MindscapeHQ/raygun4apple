//
//  RaygunFrame.m
//  raygun4apple
//
//  Created by raygundev on 8/2/18.
//

#import "RaygunFrame.h"

@implementation RaygunFrame

-(id)init {
    self = [super init];
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    dict[@"symbol"] = [NSMutableDictionary new];
    
    if (self.symbolName) {
        dict[@"symbol"][@"name"] = self.symbolName;
    }
    if (self.symbolAddress) {
        dict[@"symbol"][@"startAddress"] = self.symbolAddress;
    }
    if (self.instructionAddress) {
        dict[@"programCounter"] = self.instructionAddress;
    }
    
    return dict;
}

@end
