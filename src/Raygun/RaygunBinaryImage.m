//
//  RaygunBinaryImage.m
//  raygun4apple
//
//  Created by raygundev on 8/3/18.
//

#import <Foundation/Foundation.h>
#import "RaygunBinaryImage.h"

@implementation RaygunBinaryImage

- (id)initWithUuId:(NSString *)uuid
          withName:(NSString *)name
       withCpuType:(NSNumber *)cpuType
    withCpuSubType:(NSNumber *)cpuSubType
  withImageAddress:(NSNumber *)imageAddress
     withImageSize:(NSNumber *)imageSize
{
    if ((self = [super init])) {
        self.uuid = uuid;
        self.name = name;
        self.cpuType = cpuType;
        self.cpuSubtype = cpuSubType;
        self.imageAddress = imageAddress;
        self.imageSize= imageSize;
    }
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    if (self.uuid) {
        dict[@"uuid"] = self.uuid;
    }
    if (self.name) {
        dict[@"name"] = self.name;
    }
    if (self.cpuType) {
        dict[@"cpuType"] = self.cpuType;
    }
    if (self.cpuSubtype) {
        dict[@"cpuSubtype"] = self.cpuSubtype;
    }
    if (self.imageAddress) {
        dict[@"imageAddress"] = self.imageAddress;
    }
    if (self.imageSize) {
        dict[@"imageSize"] = self.imageSize;
    }
    
    return dict;
}

@end
