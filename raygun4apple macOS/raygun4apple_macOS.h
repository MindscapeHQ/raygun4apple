//
//  raygun4apple_macOS.h
//  raygun4apple macOS
//
//  Created by raygundev on 7/30/18.
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

#import <Cocoa/Cocoa.h>

//! Project version number for raygun4apple_macOS.
FOUNDATION_EXPORT double raygun4apple_macOSVersionNumber;

//! Project version string for raygun4apple_macOS.
FOUNDATION_EXPORT const unsigned char raygun4apple_macOSVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <raygun4apple_macOS/PublicHeader.h>

#import "RaygunClient.h"
#import "RaygunBinaryImage.h"
#import "RaygunClientMessage.h"
#import "RaygunDefines.h"
#import "RaygunEnvironmentMessage.h"
#import "RaygunErrorMessage.h"
#import "RaygunFrame.h"
#import "RaygunMessage.h"
#import "RaygunMessageDetails.h"
#import "RaygunThread.h"
#import "RaygunUserInformation.h"
#import "RaygunBreadcrumb.h"
