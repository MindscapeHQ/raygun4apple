//
//  RaygunEnvironmentMessage.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 11/09/17.
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

#import "RaygunEnvironmentMessage.h"

#import "RaygunUtils.h"

@implementation RaygunEnvironmentMessage

- (NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (_processorCount) {
        dict[@"processorCount"] = _processorCount;
    }
    
    if (![RaygunUtils isNullOrEmpty:_oSVersion]) {
        dict[@"oSVersion"] = _oSVersion;
    }
    
    if (![RaygunUtils isNullOrEmpty:_model]) {
        dict[@"model"] = _model;
    }
    
    if (_windowsBoundWidth) {
        dict[@"windowBoundsWidth"] = _windowsBoundWidth;
    }
    
    if (_windowsBoundHeight) {
        dict[@"windowBoundsHeight"] = _windowsBoundHeight;
    }
    
    if (_resolutionScale) {
        dict[@"resolutionScale"] = _resolutionScale;
    }
    
    if (![RaygunUtils isNullOrEmpty:_cpu]) {
        dict[@"cpu"] = _cpu;
    }
    
    if (_utcOffset) {
        dict[@"utcOffset"] = _utcOffset;
    }
    
    if (![RaygunUtils isNullOrEmpty:_locale]) {
        dict[@"locale"] = _locale;
    }
    
    if (![RaygunUtils isNullOrEmpty:_kernelVersion]) {
        dict[@"kernelVersion"] = _kernelVersion;
    }
    
    if (_memorySize) {
        dict[@"totalPhysicalMemory"] = _memorySize;
    }
    
    if (_memoryFree) {
        dict[@"availablePhysicalMemory"] = _memoryFree;
    }
    
    dict[@"rooted"] = _jailBroken?@YES:@NO;
    
    return dict;
}

@end
