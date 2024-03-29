//
//  UIViewController+RaygunRUM.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 3/09/18.
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

#import <TargetConditionals.h>
#if !TARGET_OS_OSX

#ifndef UIViewController_RaygunRUM_h
#define UIViewController_RaygunRUM_h

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

@interface UIViewController (RaygunRUM)

+ (void)load;

+ (void)swizzleOriginalSelector:(SEL)originalSelector withNewSelector:(SEL)swizzledSelector;

- (void)loadViewCapture;

- (void)viewDidLoadCapture;

- (void)viewWillAppearCapture:(BOOL)animated;

- (void)viewDidAppearCapture:(BOOL)animated;

@end

#endif /* UIViewController_RaygunRUM_h */
#endif /* !Target_OS_OSX */
