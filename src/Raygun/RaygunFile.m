//
//  RaygunFile.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 25/09/18.
//

#import "RaygunFile.h"


@implementation RaygunFile

- (instancetype)initWithPath:(NSString *)path withData:(NSData *)data {
    if (self = [super init]) {
        _path = path;
        _data = data;
    }
    return self;
}

@end
