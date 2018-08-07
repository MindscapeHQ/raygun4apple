//
//  RaygunNetworkLogger.h
//  Raygun4iOS
//
//  Created by Mitchell Duncan on 17/10/16.
//  Copyright © 2016 Mindscape. All rights reserved.
//

#ifndef Raygun4iOS_RaygunNetworkLogger_h
#define Raygun4iOS_RaygunNetworkLogger_h

@interface RaygunNetworkLogger : NSObject

- (void)setEnabled:(bool)enabled;
- (void)ignoreURLs:(NSArray *)urls;

@end

@interface RaygunSessionTaskDelegate: NSObject

@end

#endif
