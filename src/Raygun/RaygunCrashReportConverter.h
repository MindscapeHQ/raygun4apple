//
//  RaygunCrashReportConverter.h
//  raygun4apple
//
//  Created by raygundev on 8/1/18.
//

#import <Foundation/Foundation.h>
#import "RaygunMessage.h"

@interface RaygunCrashReportConverter : NSObject

@property (nonatomic, readwrite) bool omitMachineName;

- (RaygunMessage *)convertReportToMessage:(NSDictionary *)report;

@end
