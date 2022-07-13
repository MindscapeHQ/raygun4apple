//
//  RaygunCrashReportCustomSink.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 24/08/18.
//  Copyright © 2018 Raygun Limited. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#ifndef RaygunCrashReportCustomSink_h
#define RaygunCrashReportCustomSink_h

#import <Foundation/Foundation.h>
#import "Raygun_KSCrash.h"

@interface RaygunCrashReportCustomSink : NSObject <Raygun_KSCrashReportFilter>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTags:(NSArray *)tags withCustomData:(NSDictionary *)customData NS_DESIGNATED_INITIALIZER;

@end

#endif /* RaygunCrashReportCustomSink_h */
