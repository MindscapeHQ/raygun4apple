//
//  RaygunCrashReportCustomSink.h
//  TestiOSWithSrc
//
//  Created by Mitchell Duncan on 24/08/18.
//  Copyright © 2018 Raygun. All rights reserved.
//

#ifndef RaygunCrashReportCustomSink_h
#define RaygunCrashReportCustomSink_h

#import <Foundation/Foundation.h>
#import "KSCrash.h"

@interface RaygunCrashReportCustomSink : NSObject <KSCrashReportFilter>

-(id)initWithTags:(NSArray *)tags withCustomData:(NSDictionary *)customData;

@end

#endif /* RaygunCrashReportCustomSink_h */
