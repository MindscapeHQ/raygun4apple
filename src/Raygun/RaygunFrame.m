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
    
    if (self.symbolName) {
        dict[@"symbolName"] = self.symbolName;
    }
    if (self.symbolAddress) {
        dict[@"symbolAddress"] = self.symbolAddress;
    }
    if (self.instructionAddress) {
        dict[@"instructionAddress"] = self.instructionAddress;
    }
    if (self.binaryName) {
        dict[@"binaryName"] = self.binaryName;
    }
    if (self.symbolName) {
        dict[@"symbolName"] = self.symbolName;
    }
    
    return dict;
}

@end
